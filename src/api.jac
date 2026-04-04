import from src.models {
    Organization,
    Channel,
    Member,
    Message,
    FileRecord,
    get_organizations,
    get_organization_by_name,
    get_channels_for_org,
    get_members_for_org,
    get_member_count,
    ensure_channel,
    get_messages,
    get_files
}
import from .tools {
    post_message,
    add_file_record
}
import from .agents {
    ask_organization_agent,
    ask_channel_agent,
    build_agent_tree
}
import from .seed { seed_demo_data }

def:pub bootstrap_demo() -> dict {
    seed_demo_data();
    return {
        "status": "ok",
        "message": "Demo data bootstrapped successfully."
    };
}

def:pub list_organizations() -> list[Organization] {
    seed_demo_data();
    return get_organizations();
}

def:pub get_organization_info(org_name: str) -> dict {
    seed_demo_data();
    org = get_organization_by_name(org_name);
    if not org {
        return {};
    }
    return {
        "name": org.name,
        "description": org.description,
        "member_count": get_member_count(org_name),
        "channel_count": len(get_channels_for_org(org_name))
    };
}

def:pub list_organization_channels(org_name: str) -> list[Channel] {
    seed_demo_data();
    return get_channels_for_org(org_name);
}

def:pub list_organization_members(org_name: str) -> list[Member] {
    seed_demo_data();
    return get_members_for_org(org_name);
}

def:pub get_organization_member_count(org_name: str) -> dict {
    seed_demo_data();
    return {"organization": org_name, "member_count": get_member_count(org_name)};
}

def:pub create_channel(org_name: str, name: str, topic: str, visibility: str = "public") -> Channel {
    return ensure_channel(org_name, name, topic, visibility);
}

def:pub list_messages(org_name: str, channel_name: str = "general") -> list[Message] {
    seed_demo_data();
    return get_messages(org_name, channel_name);
}

def:pub create_message(org_name: str, channel_name: str, author: str, content: str) -> Message {
    return post_message(org_name, channel_name, author, content);
}

def:pub list_files(org_name: str, channel_name: str = "general") -> list[FileRecord] {
    seed_demo_data();
    return get_files(org_name, channel_name);
}

def:pub create_file_record(
    org_name: str,
    channel_name: str,
    filename: str,
    uploaded_by: str,
    url_or_path: str,
    summary: str,
    tags: list[str] = []
) -> FileRecord {
    return add_file_record(org_name, channel_name, filename, uploaded_by, url_or_path, summary, tags);
}

def:pub ask_organization(org_name: str, prompt: str) -> dict {
    seed_demo_data();
    return ask_organization_agent(org_name, prompt);
}

def:pub ask_channel(org_name: str, channel_name: str, prompt: str) -> dict {
    seed_demo_data();
    return ask_channel_agent(org_name, channel_name, prompt);
}

def:pub get_agent_tree(org_name: str) -> dict {
    seed_demo_data();
    return build_agent_tree(org_name);
}
