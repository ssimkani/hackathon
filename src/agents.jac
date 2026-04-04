import from byllm.llm { Model }
import from .models {
    get_organizations,
    get_organization_by_name,
    get_channels_for_org,
    get_channel_by_org_and_name,
    ensure_general_agent,
    ensure_channel_agent,
    ensure_message_agent,
    ensure_file_agent
}
import from .tools {
    list_recent_messages,
    search_messages,
    post_message,
    summarize_recent_messages,
    list_files,
    search_files,
    add_file_record,
    summarize_files
}

glob llm: Model = Model(model_name="gpt-4o");

sem choose_organization = """
Choose the best organization name from the provided options.
Return only one organization name from the options.
""";

sem choose_channel = """
Choose the best channel name from the provided options.
Return only one channel name from the options.
""";

sem choose_domain = """
Choose whether the user request is about messages or files.
Return only one word: messages or files.
""";

def choose_organization(prompt: str, organization_options: list[str]) -> str by llm(temperature=0.1);
def choose_channel(prompt: str, channel_options: list[str]) -> str by llm(temperature=0.1);
def choose_domain(prompt: str) -> str by llm(temperature=0.1);

def organization_catalog() -> list[dict] {
    return [
        {
            "name": org.name,
            "description": org.description,
            "member_count": org.member_count
        }
        for org in get_organizations()
    ];
}

def channel_catalog(org_name: str) -> list[dict] {
    return [
        {
            "name": channel.name,
            "topic": channel.topic,
            "visibility": channel.visibility
        }
        for channel in get_channels_for_org(org_name)
    ];
}

def route_organization(prompt: str) -> str {
    orgs = get_organizations();
    options = [org.name for org in orgs];
    if len(options) == 0 {
        return "";
    }
    selected = choose_organization(prompt, options);
    for option in options {
        if selected.lower() == option.lower() {
            return option;
        }
    }
    prompt_lower = prompt.lower();
    for option in options {
        if option.lower() in prompt_lower {
            return option;
        }
    }
    return options[0];
}

def route_channel(org_name: str, prompt: str) -> str {
    channels = get_channels_for_org(org_name);
    options = [channel.name for channel in channels];
    if len(options) == 0 {
        return "general";
    }
    selected = choose_channel(prompt, options);
    for option in options {
        if selected.lower() == option.lower() {
            return option;
        }
    }
    prompt_lower = prompt.lower();
    for option in options {
        if option.lower() in prompt_lower {
            return option;
        }
    }
    return options[0];
}

def route_domain(prompt: str) -> str {
    selected = choose_domain(prompt);
    if selected.lower() == "files" {
        return "files";
    }
    if selected.lower() == "messages" {
        return "messages";
    }
    prompt_lower = prompt.lower();
    for word in ["file", "pdf", "doc", "document", "upload", "link", "share"] {
        if word in prompt_lower {
            return "files";
        }
    }
    return "messages";
}

def build_agent_tree(org_name: str) -> dict {
    ensure_general_agent(org_name);
    channels = get_channels_for_org(org_name);
    return {
        "organization": org_name,
        "root": {
            "name": "organization-coordinator",
            "type": "general_agent",
            "children": [
                {
                    "name": channel.name + "-channel-agent",
                    "type": "channel_agent",
                    "channel": channel.name,
                    "children": [
                        {"name": channel.name + "-message-agent", "type": "message_agent", "channel": channel.name},
                        {"name": channel.name + "-file-agent", "type": "file_agent", "channel": channel.name}
                    ]
                }
                for channel in channels
            ]
        }
    };
}

def run_message_agent(org_name: str, channel_name: str, prompt: str) -> dict {
    ensure_message_agent(org_name, channel_name);
    prompt_lower = prompt.lower();
    if "post" in prompt_lower or "send" in prompt_lower or "announce" in prompt_lower {
        content = prompt;
        if "that " in prompt_lower {
            parts = prompt.split("that ");
            if len(parts) > 1 {
                content = parts[1];
            }
        }
        created = post_message(org_name, channel_name, "Assistant", content);
        summary = summarize_recent_messages(org_name, channel_name);
        return {
            "channel": channel_name,
            "domain": "messages",
            "tool_result": {"action": "post_message", "created": created, "summary": summary},
            "response": f"Message agent posted an update in #{channel_name} for {org_name}."
        };
    }
    if "search" in prompt_lower or "find" in prompt_lower {
        results = search_messages(org_name, channel_name, prompt);
        summary = summarize_recent_messages(org_name, channel_name);
        return {
            "channel": channel_name,
            "domain": "messages",
            "tool_result": {"action": "search_messages", "results": results, "summary": summary},
            "response": f"Message agent searched #{channel_name} in {org_name} and found {len(results)} matching messages."
        };
    }
    results = list_recent_messages(org_name, channel_name, 8);
    summary = summarize_recent_messages(org_name, channel_name);
    return {
        "channel": channel_name,
        "domain": "messages",
        "tool_result": {"action": "summarize_recent_messages", "results": results, "summary": summary},
        "response": f"Message agent summarized recent conversation in #{channel_name} for {org_name}."
    };
}

def run_file_agent(org_name: str, channel_name: str, prompt: str) -> dict {
    ensure_file_agent(org_name, channel_name);
    prompt_lower = prompt.lower();
    if "add file" in prompt_lower or "register file" in prompt_lower {
        created = add_file_record(
            org_name,
            channel_name,
            "new-file.txt",
            "Assistant",
            "/shared/new-file.txt",
            prompt,
            ["new", channel_name]
        );
        summary = summarize_files(org_name, channel_name);
        return {
            "channel": channel_name,
            "domain": "files",
            "tool_result": {"action": "add_file_record", "created": created, "summary": summary},
            "response": f"File agent added a file record in #{channel_name} for {org_name}."
        };
    }
    if "find" in prompt_lower or "search" in prompt_lower or "pdf" in prompt_lower {
        results = search_files(org_name, channel_name, prompt);
        summary = summarize_files(org_name, channel_name);
        return {
            "channel": channel_name,
            "domain": "files",
            "tool_result": {"action": "search_files", "results": results, "summary": summary},
            "response": f"File agent searched #{channel_name} in {org_name} and found {len(results)} matching files."
        };
    }
    results = list_files(org_name, channel_name, 8);
    summary = summarize_files(org_name, channel_name);
    return {
        "channel": channel_name,
        "domain": "files",
        "tool_result": {"action": "summarize_files", "results": results, "summary": summary},
        "response": f"File agent summarized shared files in #{channel_name} for {org_name}."
    };
}

def ask_organization_agent(org_name: str, prompt: str) -> dict {
    ensure_general_agent(org_name);
    selected_channel = route_channel(org_name, prompt);
    selected_domain = route_domain(prompt);
    leaf_result = run_file_agent(org_name, selected_channel, prompt) if selected_domain == "files" else run_message_agent(org_name, selected_channel, prompt);
    return {
        "prompt": prompt,
        "selected_organization": org_name,
        "selected_channel": selected_channel,
        "selected_domain": selected_domain,
        "general_agent": f"Root assistant selected {org_name} and routed the request to #{selected_channel}.",
        "channel_agent": f"Channel agent for #{selected_channel} routed the request to the {selected_domain} specialist.",
        "leaf_agent": leaf_result["response"],
        "agent_tree": build_agent_tree(org_name),
        "result": leaf_result
    };
}

def ask_channel_agent(org_name: str, channel_name: str, prompt: str) -> dict {
    ensure_channel_agent(org_name, channel_name);
    selected_domain = route_domain(prompt);
    leaf_result = run_file_agent(org_name, channel_name, prompt) if selected_domain == "files" else run_message_agent(org_name, channel_name, prompt);
    return {
        "prompt": prompt,
        "selected_organization": org_name,
        "selected_channel": channel_name,
        "selected_domain": selected_domain,
        "general_agent": f"Root assistant stayed inside {org_name}.",
        "channel_agent": f"Channel agent for #{channel_name} routed the request to the {selected_domain} specialist.",
        "leaf_agent": leaf_result["response"],
        "agent_tree": build_agent_tree(org_name),
        "result": leaf_result
    };
}
