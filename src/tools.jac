import from .models {
    Message,
    FileRecord,
    get_channel_by_org_and_name,
    get_messages,
    get_files
}

def list_recent_messages(org_name: str, channel_name: str, limit: int = 8) -> list[Message] {
    messages = get_messages(org_name, channel_name);
    if len(messages) <= limit {
        return messages;
    }
    return messages[len(messages) - limit:];
}

def search_messages(org_name: str, channel_name: str, query: str) -> list[Message] {
    query_lower = query.lower();
    return [
        message
        for message in get_messages(org_name, channel_name)
        if query_lower in message.content.lower() or query_lower in message.author.lower()
    ];
}

def post_message(org_name: str, channel_name: str, author: str, content: str) -> Message {
    channel = get_channel_by_org_and_name(org_name, channel_name);
    if not channel {
        return;
    }
    return (channel ++> Message(author=author, content=content, organization_name=org_name, channel_name=channel_name))[0];
}

def summarize_recent_messages(org_name: str, channel_name: str) -> dict {
    recent = list_recent_messages(org_name, channel_name, 5);
    if len(recent) == 0 {
        return {
            "organization": org_name,
            "channel": channel_name,
            "summary": "No messages yet.",
            "highlights": []
        };
    }
    return {
        "organization": org_name,
        "channel": channel_name,
        "summary": f"{len(recent)} recent messages captured for {org_name} / {channel_name}.",
        "highlights": [f"{msg.author}: {msg.content}" for msg in recent]
    };
}

def list_files(org_name: str, channel_name: str, limit: int = 10) -> list[FileRecord] {
    files = get_files(org_name, channel_name);
    if len(files) <= limit {
        return files;
    }
    return files[len(files) - limit:];
}

def search_files(org_name: str, channel_name: str, query: str) -> list[FileRecord] {
    query_lower = query.lower();
    return [
        file
        for file in get_files(org_name, channel_name)
        if query_lower in file.filename.lower()
        or query_lower in file.summary.lower()
        or query_lower in file.url_or_path.lower()
        or query_lower in " ".join(file.tags).lower()
    ];
}

def add_file_record(
    org_name: str,
    channel_name: str,
    filename: str,
    uploaded_by: str,
    url_or_path: str,
    summary: str,
    tags: list[str] = []
) -> FileRecord {
    channel = get_channel_by_org_and_name(org_name, channel_name);
    if not channel {
        return;
    }
    return (channel ++> FileRecord(
        filename=filename,
        uploaded_by=uploaded_by,
        url_or_path=url_or_path,
        summary=summary,
        tags=tags,
        organization_name=org_name,
        channel_name=channel_name
    ))[0];
}

def summarize_files(org_name: str, channel_name: str) -> dict {
    files = list_files(org_name, channel_name, 5);
    if len(files) == 0 {
        return {
            "organization": org_name,
            "channel": channel_name,
            "summary": "No files shared yet.",
            "highlights": []
        };
    }
    return {
        "organization": org_name,
        "channel": channel_name,
        "summary": f"{len(files)} recent files available in {org_name} / {channel_name}.",
        "highlights": [f"{file.filename} — {file.summary}" for file in files]
    };
}
