import from datetime { datetime }

node Organization {
    has name: str = "";
    has description: str = "";
    has member_count: int = 0;
}

node Member {
    has name: str = "";
    has role: str = "";
    has organization_name: str = "";
}

node Channel {
    has name: str = "";
    has topic: str = "";
    has visibility: str = "public";
    has organization_name: str = "";
}

node Message {
    has author: str = "";
    has content: str = "";
    has created_at: str = "";
    has organization_name: str = "";
    has channel_name: str = "";

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
    has organization_name: str = "";
    has channel_name: str = "";

    def postinit {
        if not self.uploaded_at {
            self.uploaded_at = datetime.now().isoformat();
        }
    }
}

node GeneralAgent {
    has organization_name: str = "";
    has name: str = "organization-coordinator";
    has instructions: str = "Route requests to the best channel agent inside one organization. Never use tools directly.";
}

node ChannelAgent {
    has organization_name: str = "";
    has channel_name: str = "";
    has instructions: str = "Route channel requests to either the message agent or file agent. Never use tools directly.";
}

node MessageAgent {
    has organization_name: str = "";
    has channel_name: str = "";
    has instructions: str = "Use message tools for search, posting, and summaries in one organization channel.";
}

node FileAgent {
    has organization_name: str = "";
    has channel_name: str = "";
    has instructions: str = "Use file tools for search, listing, and summaries in one organization channel.";
}

def get_organizations() -> list[Organization] {
    return [root -->][?:Organization];
}

def get_organization_by_name(org_name: str) -> Organization {
    for org in get_organizations() {
        if org.name.lower() == org_name.lower() {
            return org;
        }
    }
}

def ensure_organization(name: str, description: str, member_count: int = 0) -> Organization {
    existing = get_organization_by_name(name);
    if existing {
        if description and not existing.description {
            existing.description = description;
        }
        if member_count > 0 and existing.member_count == 0 {
            existing.member_count = member_count;
        }
        return existing;
    }
    return (root ++> Organization(name=name, description=description, member_count=member_count))[0];
}

def get_members_for_org(org_name: str) -> list[Member] {
    org = get_organization_by_name(org_name);
    if not org {
        return [];
    }
    return [org-->][?:Member];
}

def get_member_count(org_name: str) -> int {
    org = get_organization_by_name(org_name);
    if not org {
        return 0;
    }
    members = get_members_for_org(org_name);
    if len(members) > 0 {
        return len(members);
    }
    return org.member_count;
}

def ensure_member(org_name: str, name: str, role: str) -> Member {
    org = get_organization_by_name(org_name);
    if not org {
        return;
    }
    for member in [org-->][?:Member] {
        if member.name.lower() == name.lower() {
            return member;
        }
    }
    member = (org ++> Member(name=name, role=role, organization_name=org_name))[0];
    org.member_count = len([org-->][?:Member]);
    return member;
}

def get_channels_for_org(org_name: str) -> list[Channel] {
    org = get_organization_by_name(org_name);
    if not org {
        return [];
    }
    return [org-->][?:Channel];
}

def get_channel_by_org_and_name(org_name: str, channel_name: str) -> Channel {
    for channel in get_channels_for_org(org_name) {
        if channel.name.lower() == channel_name.lower() {
            return channel;
        }
    }
}

def ensure_channel(org_name: str, name: str, topic: str, visibility: str = "public") -> Channel {
    existing = get_channel_by_org_and_name(org_name, name);
    if existing {
        return existing;
    }
    org = get_organization_by_name(org_name);
    if not org {
        return;
    }
    return (org ++> Channel(name=name, topic=topic, visibility=visibility, organization_name=org_name))[0];
}

def get_messages(org_name: str, channel_name: str) -> list[Message] {
    channel = get_channel_by_org_and_name(org_name, channel_name);
    if not channel {
        return [];
    }
    return [channel-->][?:Message];
}

def get_files(org_name: str, channel_name: str) -> list[FileRecord] {
    channel = get_channel_by_org_and_name(org_name, channel_name);
    if not channel {
        return [];
    }
    return [channel-->][?:FileRecord];
}

def ensure_general_agent(org_name: str) -> GeneralAgent {
    org = get_organization_by_name(org_name);
    if not org {
        return;
    }
    agents = [org-->][?:GeneralAgent];
    if len(agents) > 0 {
        return agents[0];
    }
    return (org ++> GeneralAgent(organization_name=org_name))[0];
}

def ensure_channel_agent(org_name: str, channel_name: str) -> ChannelAgent {
    general_agent = ensure_general_agent(org_name);
    if not general_agent {
        return;
    }
    for agent in [general_agent-->][?:ChannelAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (general_agent ++> ChannelAgent(organization_name=org_name, channel_name=channel_name))[0];
}

def ensure_message_agent(org_name: str, channel_name: str) -> MessageAgent {
    channel_agent = ensure_channel_agent(org_name, channel_name);
    if not channel_agent {
        return;
    }
    for agent in [channel_agent-->][?:MessageAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (channel_agent ++> MessageAgent(organization_name=org_name, channel_name=channel_name))[0];
}

def ensure_file_agent(org_name: str, channel_name: str) -> FileAgent {
    channel_agent = ensure_channel_agent(org_name, channel_name);
    if not channel_agent {
        return;
    }
    for agent in [channel_agent-->][?:FileAgent] {
        if agent.channel_name.lower() == channel_name.lower() {
            return agent;
        }
    }
    return (channel_agent ++> FileAgent(organization_name=org_name, channel_name=channel_name))[0];
}
