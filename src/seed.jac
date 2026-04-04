import from .models {
    ensure_organization,
    ensure_member,
    ensure_channel,
    ensure_general_agent,
    ensure_channel_agent,
    ensure_message_agent,
    ensure_file_agent,
    get_messages,
    get_files,
    get_channels_for_org,
    get_member_count
}
import from .tools { post_message, add_file_record }

def seed_org(
    org_name: str,
    description: str,
    members: list[dict],
    channels: list[dict],
    messages: dict,
    files: dict
) -> None {
    ensure_organization(org_name, description, len(members));

    for member in members {
        ensure_member(org_name, member["name"], member["role"]);
    }

    for channel in channels {
        ensure_channel(org_name, channel["name"], channel["topic"], channel["visibility"]);
    }

    ensure_general_agent(org_name);
    for channel in get_channels_for_org(org_name) {
        ensure_channel_agent(org_name, channel.name);
        ensure_message_agent(org_name, channel.name);
        ensure_file_agent(org_name, channel.name);
    }

    for channel_name in messages.keys() {
        if len(get_messages(org_name, channel_name)) == 0 {
            for item in messages[channel_name] {
                post_message(org_name, channel_name, item["author"], item["content"]);
            }
        }
    }

    for channel_name in files.keys() {
        if len(get_files(org_name, channel_name)) == 0 {
            for item in files[channel_name] {
                add_file_record(
                    org_name,
                    channel_name,
                    item["filename"],
                    item["uploaded_by"],
                    item["url_or_path"],
                    item["summary"],
                    item["tags"]
                );
            }
        }
    }
}

def seed_demo_data() -> dict {
    seed_org(
        "Acme Labs",
        "Applied AI product team shipping collaboration workflows for research and delivery.",
        [
            {"name": "Maya", "role": "Product Lead"},
            {"name": "Jordan", "role": "Engineer"},
            {"name": "Ava", "role": "Platform Engineer"},
            {"name": "Nina", "role": "Designer"},
            {"name": "Leo", "role": "Ops Lead"}
        ],
        [
            {"name": "general", "topic": "Company-wide updates and quick questions.", "visibility": "public"},
            {"name": "engineering", "topic": "Deployments, bugs, architecture, and sprint execution.", "visibility": "public"},
            {"name": "design", "topic": "UX reviews, mockups, feedback, and research notes.", "visibility": "public"}
        ],
        {
            "general": [
                {"author": "Maya", "content": "Welcome to Acme Labs. Share launch updates here first."},
                {"author": "Jordan", "content": "Judging starts at 4 PM, so keep the demo tight."}
            ],
            "engineering": [
                {"author": "Ava", "content": "API routes are stable and ready for frontend wiring."},
                {"author": "Leo", "content": "Deployment rehearsal is scheduled for 5 PM."}
            ],
            "design": [
                {"author": "Nina", "content": "Uploaded the latest dashboard mockups for review."}
            ]
        },
        {
            "general": [
                {"filename": "hackathon-brief.pdf", "uploaded_by": "Maya", "url_or_path": "/files/hackathon-brief.pdf", "summary": "Event brief and judging criteria.", "tags": ["brief", "judging"]}
            ],
            "engineering": [
                {"filename": "deployment-runbook.md", "uploaded_by": "Leo", "url_or_path": "/files/deployment-runbook.md", "summary": "Step-by-step deployment checklist.", "tags": ["deploy", "ops"]}
            ],
            "design": [
                {"filename": "dashboard-mockups.fig", "uploaded_by": "Nina", "url_or_path": "https://figma.com/file/dashboard-mockups", "summary": "Latest collaboration dashboard mockups.", "tags": ["figma", "ui", "review"]}
            ]
        }
    );

    seed_org(
        "Northstar Design",
        "Brand, product, and research studio coordinating design systems and client delivery.",
        [
            {"name": "Omar", "role": "Creative Director"},
            {"name": "Priya", "role": "Research Lead"},
            {"name": "Sofia", "role": "Design Systems Engineer"},
            {"name": "Ethan", "role": "Motion Designer"}
        ],
        [
            {"name": "general", "topic": "Studio announcements and planning.", "visibility": "public"},
            {"name": "client-alpha", "topic": "Client Alpha deliverables and feedback.", "visibility": "private"},
            {"name": "research", "topic": "Interviews, notes, and synthesis.", "visibility": "public"}
        ],
        {
            "general": [
                {"author": "Omar", "content": "Kickoff for the new client sprint is tomorrow morning."}
            ],
            "client-alpha": [
                {"author": "Sofia", "content": "Shared the updated component library for Client Alpha."}
            ],
            "research": [
                {"author": "Priya", "content": "Interview synthesis deck is ready for review."}
            ]
        },
        {
            "general": [
                {"filename": "studio-calendar.pdf", "uploaded_by": "Omar", "url_or_path": "/files/studio-calendar.pdf", "summary": "Upcoming studio milestones and reviews.", "tags": ["calendar", "planning"]}
            ],
            "client-alpha": [
                {"filename": "alpha-design-system.fig", "uploaded_by": "Sofia", "url_or_path": "https://figma.com/file/alpha-design-system", "summary": "Client Alpha design system source file.", "tags": ["figma", "design-system"]}
            ],
            "research": [
                {"filename": "interview-synthesis.pdf", "uploaded_by": "Priya", "url_or_path": "/files/interview-synthesis.pdf", "summary": "Research synthesis and key themes.", "tags": ["research", "pdf"]}
            ]
        }
    );

    seed_org(
        "Orbit Ops",
        "Operations command center for support, logistics, and internal enablement.",
        [
            {"name": "Harper", "role": "Operations Manager"},
            {"name": "Noah", "role": "Support Lead"},
            {"name": "Grace", "role": "People Ops"},
            {"name": "Miles", "role": "Analyst"},
            {"name": "Zoe", "role": "Coordinator"},
            {"name": "Ivy", "role": "Recruiter"}
        ],
        [
            {"name": "general", "topic": "Ops-wide updates and coordination.", "visibility": "public"},
            {"name": "support", "topic": "Customer escalations and support handoffs.", "visibility": "public"},
            {"name": "people", "topic": "Onboarding, hiring, and internal docs.", "visibility": "private"}
        ],
        {
            "general": [
                {"author": "Harper", "content": "Weekly operations review starts at 2 PM."}
            ],
            "support": [
                {"author": "Noah", "content": "Escalation queue is back under SLA."}
            ],
            "people": [
                {"author": "Grace", "content": "Onboarding checklist is ready for new volunteers."}
            ]
        },
        {
            "general": [
                {"filename": "ops-dashboard.csv", "uploaded_by": "Miles", "url_or_path": "/files/ops-dashboard.csv", "summary": "Weekly metrics export for operations review.", "tags": ["metrics", "csv"]}
            ],
            "support": [
                {"filename": "escalation-playbook.md", "uploaded_by": "Noah", "url_or_path": "/files/escalation-playbook.md", "summary": "Support escalation process and owners.", "tags": ["support", "playbook"]}
            ],
            "people": [
                {"filename": "onboarding-guide.pdf", "uploaded_by": "Grace", "url_or_path": "/files/onboarding-guide.pdf", "summary": "New teammate onboarding guide and checklist.", "tags": ["onboarding", "people"]}
            ]
        }
    );

    return {
        "status": "ok",
        "organizations": ["Acme Labs", "Northstar Design", "Orbit Ops"],
        "counts": {
            "Acme Labs": {"members": get_member_count("Acme Labs"), "channels": len(get_channels_for_org("Acme Labs"))},
            "Northstar Design": {"members": get_member_count("Northstar Design"), "channels": len(get_channels_for_org("Northstar Design"))},
            "Orbit Ops": {"members": get_member_count("Orbit Ops"), "channels": len(get_channels_for_org("Orbit Ops"))}
        }
    };
}
