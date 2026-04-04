import from datetime { datetime }

node Workspace {
    has name: str = "";
    has description: str = "";
}

node Channel {
    has name: str = "";
    has topic: str = "";
    has visibility: str = "public";
}

node Message {
    has author: str = "";
    has content: str = "";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}

node FileRecord {
    has filename: str = "";
    has uploaded_by: str = "";
    has uploaded_at: str = "";
    has url_or_path: str = "";
    has summary: str = "";
    has tags: list[str] = [];

    def postinit {
        if not self.uploaded_at {
            self.uploaded_at = datetime.now().isoformat();
        }
    }
}

node GeneralAgent {
    has name: str = "workspace-coordinator";
    has instructions: str = "Route requests to the best channel agent. Never use tools directly.";
}

node ChannelAgent {
    has channel_name: str = "";
    has instructions: str = "Route channel requests to either the message agent or file agent. Never use tools directly.";
}

node MessageAgent {
    has channel_name: str = "";
    has instructions: str = "Use message tools for search, posting, and summaries in one channel.";
}

node FileAgent {
    has channel_name: str = "";
    has instructions: str = "Use file tools for search, listing, and summaries in one channel.";
}


def get_workspace() -> Workspace {
    workspaces = [root()-->][?:Workspace];
    if len(workspaces) > 0 {
        return workspaces[0];
    }
    return (root() ++> Workspace(
        name="Hackathon Hub",
        description="Graph-native collaboration workspace for messaging, files, and agentic routing."
    ))[0];
}


def get_channels() -> list[Channel] {
    workspace = get_workspace();
    return [workspace-->][?:Channel];
}


def get_channel_by_name(channel_name: str) -> Channel {
    for channel in get_channels() {
        if channel.name.lower() == channel_name.lower() {
            return channel;
        }
    }
}


def ensure_channel(name: str, topic: str, visibility: str = "public") -> Channel {
    existing = get_channel_by_name(name);
    if existing {
        return existing;
    }
    workspace = get_workspace();
    return (workspace ++> Channel(name=name, topic=topic, visibility=visibility))[0];
}


def get_messages(channel_name: str) -> list[Message] {
    channel = get_channel_by_name(channel_name);
    if not channel {
        return [];
    }
    return [channel-->][?:Message];
}


def get_files(channel_name: str) -> list[FileRecord] {
    channel = get_channel_by_name(channel_name);
    if not channel {
        return [];
    }
    return [channel-->][?:FileRecord];
}


def ensure_general_agent() -> GeneralAgent {
    workspace = get_workspace();
    agents = [workspace-->][?:GeneralAgent];
    if len(agents) > 0 {
        return agents[0];
    }
    return (workspace ++> GeneralAgent())[0];
}


def ensure_channel_agent(channel_name: str) -> ChannelAgent {
    general_agent = ensure_general_agent();
    for agent in [general_agent-->][?:ChannelAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (general_agent ++> ChannelAgent(channel_name=channel_name))[0];
}


def ensure_message_agent(channel_name: str) -> MessageAgent {
    channel_agent = ensure_channel_agent(channel_name);
    for agent in [channel_agent-->][?:MessageAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (channel_agent ++> MessageAgent(channel_name=channel_name))[0];
}


def ensure_file_agent(channel_name: str) -> FileAgent {
    channel_agent = ensure_channel_agent(channel_name);
    for agent in [channel_agent-->][?:FileAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (channel_agent ++> FileAgent(channel_name=channel_name))[0];
}
