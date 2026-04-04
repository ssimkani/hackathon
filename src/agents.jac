import from byllm.lib { Model }
import from .models {
    get_channels,
    get_channel_by_name,
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

glob llm: Model = Model(model_name="gpt-5.4");

sem choose_channel = """
You are the workspace-level coordinator for a team collaboration app.
Choose the best channel name from the provided options.
Infer the best channel when possible.
Return only one channel name from the options.
""";

sem choose_domain = """
You are a channel-level router.
Choose whether the user request is about messages or files.
Return only one word: messages or files.
""";

sem general_agent_reply = """
You are the workspace-level coordinator.
You know all channels and their purposes.
You do not use tools.
Explain which channel you selected and why in one concise sentence.
""";

sem channel_agent_reply = """
You are a channel specialist.
You do not use tools.
Explain whether the request should go to the message agent or file agent in one concise sentence.
""";

sem message_agent_reply = """
You are a message specialist for one channel.
Use the provided tool results to answer clearly and concisely.
If the user asked to post a message, confirm the action.
""";

sem file_agent_reply = """
You are a file-share specialist for one channel.
Use the provided tool results to answer clearly and concisely.
Prefer concise summaries and direct references to filenames and links.
""";

def choose_channel(prompt: str, channel_options: list[str]) -> str by llm(method="Reason", temperature=0.1);
def choose_domain(prompt: str) -> str by llm(method="Reason", temperature=0.1);
def general_agent_reply(prompt: str, channels: list[dict], selected_channel: str) -> str by llm(method="Reason", temperature=0.2);
def channel_agent_reply(prompt: str, channel_name: str, topic: str, selected_domain: str) -> str by llm(method="Reason", temperature=0.2);
def message_agent_reply(prompt: str, channel_name: str, tool_result: dict) -> str by llm(method="Reason", tools=[list_recent_messages, search_messages, post_message, summarize_recent_messages], temperature=0.2);
def file_agent_reply(prompt: str, channel_name: str, tool_result: dict) -> str by llm(method="Reason", tools=[list_files, search_files, add_file_record, summarize_files], temperature=0.2);

def channel_catalog() -> list[dict] {
    return [
        {
            "name": channel.name,
            "topic": channel.topic,
            "visibility": channel.visibility
        }
        for channel in get_channels()
    ];
}

def route_channel(prompt: str) -> str {
    channels = get_channels();
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
    } else {
        if selected.lower() == "messages" {
            return "messages";
        } else {
            prompt_lower = prompt.lower();
            file_words = ["file", "pdf", "doc", "document", "upload", "link", "share"];
            for word in file_words {
                if word in prompt_lower {
                    return "files";
                }
            }
            return "messages";
        }
    }
}

def run_message_agent(channel_name: str, prompt: str) -> dict {
    ensure_message_agent(channel_name);
    prompt_lower = prompt.lower();
    if "post" in prompt_lower or "send" in prompt_lower or "announce" in prompt_lower {
        content = prompt;
        if "that " in prompt_lower {
            parts = prompt.split("that ");
            if len(parts) > 1 {
                content = parts[1];
            }
        }
        tool_result = {
            "action": "post_message",
            "created": post_message(channel_name, "Assistant", content),
            "summary": summarize_recent_messages(channel_name)
        };
        return {
            "channel": channel_name,
            "domain": "messages",
            "tool_result": tool_result,
            "response": message_agent_reply(prompt, channel_name, tool_result)
        };
    } else {
        if "search" in prompt_lower or "find" in prompt_lower {
            tool_result = {
                "action": "search_messages",
                "results": search_messages(channel_name, prompt),
                "summary": summarize_recent_messages(channel_name)
            };
            return {
                "channel": channel_name,
                "domain": "messages",
                "tool_result": tool_result,
                "response": message_agent_reply(prompt, channel_name, tool_result)
            };
        } else {
            tool_result = {
                "action": "summarize_recent_messages",
                "results": list_recent_messages(channel_name, 8),
                "summary": summarize_recent_messages(channel_name)
            };
            return {
                "channel": channel_name,
                "domain": "messages",
                "tool_result": tool_result,
                "response": message_agent_reply(prompt, channel_name, tool_result)
            };
        }
    }
}

def run_file_agent(channel_name: str, prompt: str) -> dict {
    ensure_file_agent(channel_name);
    prompt_lower = prompt.lower();
    if "add file" in prompt_lower or "register file" in prompt_lower {
        tool_result = {
            "action": "add_file_record",
            "created": add_file_record(
                channel_name,
                "new-file.txt",
                "Assistant",
                "/shared/new-file.txt",
                prompt,
                ["new", channel_name]
            ),
            "summary": summarize_files(channel_name)
        };
        return {
            "channel": channel_name,
            "domain": "files",
            "tool_result": tool_result,
            "response": file_agent_reply(prompt, channel_name, tool_result)
        };
    } else {
        if "find" in prompt_lower or "search" in prompt_lower or "pdf" in prompt_lower {
            tool_result = {
                "action": "search_files",
                "results": search_files(channel_name, prompt),
                "summary": summarize_files(channel_name)
            };
            return {
                "channel": channel_name,
                "domain": "files",
                "tool_result": tool_result,
                "response": file_agent_reply(prompt, channel_name, tool_result)
            };
        } else {
            tool_result = {
                "action": "summarize_files",
                "results": list_files(channel_name, 8),
                "summary": summarize_files(channel_name)
            };
            return {
                "channel": channel_name,
                "domain": "files",
                "tool_result": tool_result,
                "response": file_agent_reply(prompt, channel_name, tool_result)
            };
        }
    }
}

def ask_workspace_agent(prompt: str) -> dict {
    ensure_general_agent();
    selected_channel = route_channel(prompt);
    channel = get_channel_by_name(selected_channel);
    selected_domain = route_domain(prompt);
    general_note = general_agent_reply(prompt, channel_catalog(), selected_channel);
    channel_note = channel_agent_reply(prompt, selected_channel, channel.topic if channel else "", selected_domain);
    leaf_result = run_file_agent(selected_channel, prompt) if selected_domain == "files" else run_message_agent(selected_channel, prompt);
    return {
        "prompt": prompt,
        "selected_channel": selected_channel,
        "selected_domain": selected_domain,
        "general_agent": general_note,
        "channel_agent": channel_note,
        "leaf_agent": leaf_result["response"],
        "result": leaf_result
    };
}

def ask_channel_agent(channel_name: str, prompt: str) -> dict {
    ensure_channel_agent(channel_name);
    channel = get_channel_by_name(channel_name);
    selected_domain = route_domain(prompt);
    channel_note = channel_agent_reply(prompt, channel_name, channel.topic if channel else "", selected_domain);
    leaf_result = run_file_agent(channel_name, prompt) if selected_domain == "files" else run_message_agent(channel_name, prompt);
    return {
        "prompt": prompt,
        "selected_channel": channel_name,
        "selected_domain": selected_domain,
        "channel_agent": channel_note,
        "leaf_agent": leaf_result["response"],
        "result": leaf_result
    };
}
