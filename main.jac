import from src.api {
    bootstrap_demo,
    get_workspace_info,
    list_channels,
    create_channel,
    list_messages,
    create_message,
    list_files,
    create_file_record,
    ask_workspace,
    ask_channel
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
