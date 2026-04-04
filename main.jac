import from src.api {
    bootstrap_demo,
    list_organizations,
    get_organization_info,
    list_organization_channels,
    list_organization_members,
    get_organization_member_count,
    create_channel,
    list_messages,
    create_message,
    list_files,
    create_file_record,
    ask_organization,
    ask_channel,
    get_agent_tree
}
import from src.seed { seed_demo_data }

cl import ".styles.global.css";
cl import from .src.ui { AppShell }

with entry {
    seed_demo_data();
}

cl {
    def:pub app() -> JsxElement {
        return <AppShell />;
    }
}
