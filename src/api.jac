import from .models {
    Channel,
    Message,
    FileRecord,
    get_workspace,
    get_channels,
    ensure_channel,
    get_messages,
    get_files
}
import from .tools {
    post_message,
    add_file_record
}
import from .agents {
    ask_workspace_agent,
    ask_channel_agent
}
import from .seed { seed_demo_data }

def:pub bootstrap_demo() -> dict {
    return seed_demo_data();
}

def:pub get_workspace_info() -> dict {
    seed_demo_data();
    workspace = get_workspace();
    return {
        "name": workspace.name,
        "description": workspace.description
    };
}

def:pub list_channels() -> list[Channel] {
    seed_demo_data();
    return get_channels();
}

def:pub create_channel(name: str, topic: str, visibility: str = "public") -> Channel {
    return ensure_channel(name, topic, visibility);
}

def:pub list_messages(channel_name: str = "general") -> list[Message] {
    seed_demo_data();
    return get_messages(channel_name);
}

def:pub create_message(channel_name: str, author: str, content: str) -> Message {
    return post_message(channel_name, author, content);
}

def:pub list_files(channel_name: str = "general") -> list[FileRecord] {
    seed_demo_data();
    return get_files(channel_name);
}

def:pub create_file_record(
    channel_name: str,
    filename: str,
    uploaded_by: str,
    url_or_path: str,
    summary: str,
    tags: list[str] = []
) -> FileRecord {
    return add_file_record(channel_name, filename, uploaded_by, url_or_path, summary, tags);
}

def:pub ask_workspace(prompt: str) -> dict {
    seed_demo_data();
    return ask_workspace_agent(prompt);
}

def:pub ask_channel(channel_name: str, prompt: str) -> dict {
    seed_demo_data();
    return ask_channel_agent(channel_name, prompt);
}
