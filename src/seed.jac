import from .models {
    ensure_channel,
    ensure_general_agent,
    ensure_channel_agent,
    ensure_message_agent,
    ensure_file_agent,
    get_messages,
    get_files
}
import from .tools { post_message, add_file_record }

def seed_demo_data() -> dict {
    channels = [
        ensure_channel("general", "Company-wide updates, announcements, and quick questions."),
        ensure_channel("engineering", "Deployments, bugs, architecture, and sprint execution."),
        ensure_channel("design", "UX reviews, mockups, feedback, and research notes."),
        ensure_channel("hr", "Onboarding, policies, people operations, and hiring coordination.")
    ];

    ensure_general_agent();
    for channel in channels {
        ensure_channel_agent(channel.name);
        ensure_message_agent(channel.name);
        ensure_file_agent(channel.name);
    }

    if len(get_messages("general")) == 0 {
        post_message("general", "Maya", "Welcome to Hackathon Hub. Share updates here first.");
        post_message("general", "Jordan", "Judging starts at 4 PM, so keep the demo tight.");
    }
    if len(get_messages("engineering")) == 0 {
        post_message("engineering", "Ava", "API routes are stable and ready for frontend wiring.");
        post_message("engineering", "Leo", "Deployment rehearsal is scheduled for 5 PM.");
    }
    if len(get_messages("design")) == 0 {
        post_message("design", "Nina", "Uploaded the latest dashboard mockups for review.");
        post_message("design", "Omar", "Need feedback on the assistant panel spacing.");
    }
    if len(get_messages("hr")) == 0 {
        post_message("hr", "Priya", "Onboarding checklist is ready for new volunteers.");
    }

    if len(get_files("general")) == 0 {
        add_file_record("general", "hackathon-brief.pdf", "Maya", "/files/hackathon-brief.pdf", "Event brief and judging criteria.", ["brief", "judging"]);
    }
    if len(get_files("engineering")) == 0 {
        add_file_record("engineering", "deployment-runbook.md", "Leo", "/files/deployment-runbook.md", "Step-by-step deployment checklist.", ["deploy", "ops"]);
    }
    if len(get_files("design")) == 0 {
        add_file_record("design", "dashboard-mockups.fig", "Nina", "https://figma.com/file/dashboard-mockups", "Latest collaboration dashboard mockups.", ["figma", "ui", "review"]);
    }
    if len(get_files("hr")) == 0 {
        add_file_record("hr", "onboarding-guide.pdf", "Priya", "/files/onboarding-guide.pdf", "New teammate onboarding guide and checklist.", ["onboarding", "pdf", "people"]);
    }

    return {
        "status": "ok",
        "channels": [channel.name for channel in channels]
    };
}
