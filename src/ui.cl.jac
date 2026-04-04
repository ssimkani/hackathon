sv import from .api {
    bootstrap_demo,
    get_workspace_info,
    list_channels,
    list_messages as api_list_messages,
    create_message as api_create_message,
    list_files as api_list_files,
    ask_workspace as api_ask_workspace,
    ask_channel as api_ask_channel
}

def ChannelPill(channel: any, active_name: str, on_select: any) -> JsxElement {
    if not channel {
        return <span />;
    }
    is_active = channel.name == active_name;
    button_class = "w-full rounded-xl border px-4 py-3 text-left transition-all " + (
        "border-primary bg-primary/15 text-foreground shadow-soft" if is_active else "border-border bg-card text-foreground hover:bg-card-hover"
    );
    def handle_click() -> None {
        on_select(channel.name);
    }
    return <button className={button_class} onClick={handle_click}>
        <div className="flex items-center justify-between gap-3">
            <div>
                <div className="text-sm font-semibold">#{channel.name}</div>
                <div className="mt-1 text-xs text-muted-foreground">{channel.topic}</div>
            </div>
            <div className="rounded-full border border-border px-2 py-1 text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
                {channel.visibility}
            </div>
        </div>
    </button>;
}

def MessageCard(message: any) -> JsxElement {
    if not message {
        return <span />;
    }
    return <div className="rounded-2xl border border-border bg-card p-4 shadow-soft">
        <div className="flex items-center justify-between gap-3">
            <div className="text-sm font-semibold text-foreground">{message.author}</div>
            <div className="text-xs text-muted-foreground">{message.created_at}</div>
        </div>
        <div className="mt-3 text-sm leading-6 text-foreground/90">{message.content}</div>
    </div>;
}

def FileCard(file: any) -> JsxElement {
    if not file {
        return <span />;
    }
    return <div className="rounded-2xl border border-border bg-card p-4 shadow-soft">
        <div className="flex items-start justify-between gap-3">
            <div>
                <div className="text-sm font-semibold text-foreground">{file.filename}</div>
                <div className="mt-1 text-xs text-muted-foreground">Uploaded by {file.uploaded_by}</div>
            </div>
            <a className="rounded-full border border-border px-3 py-1 text-xs text-primary hover:bg-primary/10" href={file.url_or_path} target="_blank">
                Open
            </a>
        </div>
        <div className="mt-3 text-sm text-foreground/85">{file.summary}</div>
        <div className="mt-3 flex flex-wrap gap-2">
            {[<span className="rounded-full bg-muted px-2.5 py-1 text-[11px] text-muted-foreground">{tag}</span> for tag in file.tags if tag]}
        </div>
    </div>;
}

def AgentPanel(result: any) -> JsxElement {
    if not result {
        return <div className="rounded-2xl border border-dashed border-border bg-card/60 p-5 text-sm text-muted-foreground">
            Ask the workspace assistant to route a request across channels.
        </div>;
    }
    return <div className="rounded-2xl border border-border bg-card p-5 shadow-card">
        <div className="flex flex-wrap items-center gap-2 text-xs uppercase tracking-[0.2em] text-muted-foreground">
            <span>Workspace route</span>
            <span className="rounded-full bg-primary/15 px-2 py-1 text-primary">#{result.selected_channel}</span>
            <span className="rounded-full bg-muted px-2 py-1">{result.selected_domain}</span>
        </div>
        <div className="mt-4 space-y-3 text-sm leading-6 text-foreground/90">
            <div><span className="font-semibold text-foreground">General agent:</span> {result.general_agent}</div>
            <div><span className="font-semibold text-foreground">Channel agent:</span> {result.channel_agent}</div>
            <div><span className="font-semibold text-foreground">Leaf agent:</span> {result.leaf_agent}</div>
        </div>
    </div>;
}

def:pub AppShell() -> JsxElement {
    has workspace: dict = {}, channels: list = [], selected_channel: str = "general", messages: list = [], files: list = [], assistant_prompt: str = "Summarize what happened in design today", assistant_result: dict = {}, message_input: str = "", loading: bool = True;

    async can with entry {
        await bootstrap_demo();
        workspace = await get_workspace_info() or {};
        channels = await list_channels() or [];
        if len(channels) > 0 {
            selected_channel = channels[0].name;
        }
        messages = await api_list_messages(selected_channel) or [];
        files = await api_list_files(selected_channel) or [];
        loading = False;
    }

    async def refresh_channel(channel_name: str) -> None {
        selected_channel = channel_name;
        messages = await api_list_messages(channel_name) or [];
        files = await api_list_files(channel_name) or [];
    }

    def handle_message_input(e: any) -> None {
        message_input = e.target.value;
    }

    def handle_assistant_input(e: any) -> None {
        assistant_prompt = e.target.value;
    }

    async def send_message() -> None {
        if not message_input.strip() {
            return;
        }
        await api_create_message(selected_channel, "You", message_input.strip());
        message_input = "";
        messages = await api_list_messages(selected_channel) or [];
    }

    async def run_workspace_assistant() -> None {
        if not assistant_prompt.strip() {
            return;
        }
        assistant_result = await api_ask_workspace(assistant_prompt.strip()) or {};
        if assistant_result {
            await refresh_channel(assistant_result.selected_channel);
        }
    }

    async def run_channel_assistant() -> None {
        if not assistant_prompt.strip() {
            return;
        }
        assistant_result = await api_ask_channel(selected_channel, assistant_prompt.strip()) or {};
        await refresh_channel(selected_channel);
    }

    if loading {
        return <div className="min-h-screen bg-background px-6 py-10 text-foreground">
            <div className="mx-auto max-w-7xl animate-pulse rounded-3xl border border-border bg-card p-10 shadow-card">
                Loading Hackathon Hub...
            </div>
        </div>;
    }

    return <div className="min-h-screen bg-background px-4 py-6 text-foreground md:px-6 lg:px-8">
        <div className="mx-auto max-w-7xl">
            <div className="mb-6 flex flex-col gap-4 rounded-3xl border border-border bg-card/80 p-6 shadow-card backdrop-blur md:flex-row md:items-end md:justify-between">
                <div>
                    <div className="text-xs uppercase tracking-[0.3em] text-primary">Jac + Jaseci agentic workspace</div>
                    <h1 className="mt-2 text-3xl font-extrabold tracking-tight">{workspace.name}</h1>
                    <p className="mt-2 max-w-3xl text-sm text-muted-foreground">{workspace.description}</p>
                </div>
                <div className="rounded-2xl border border-border bg-muted/60 px-4 py-3 text-sm text-muted-foreground">
                    Tree routing: workspace agent → channel agent → leaf tool agent
                </div>
            </div>

            <div className="grid gap-6 lg:grid-cols-[280px_minmax(0,1fr)_360px]">
                <aside className="space-y-4 rounded-3xl border border-border bg-card/80 p-5 shadow-card backdrop-blur">
                    <div>
                        <div className="text-sm font-semibold">Channels</div>
                        <div className="mt-1 text-xs text-muted-foreground">Seeded demo channels for your hackathon story.</div>
                    </div>
                    <div className="space-y-3">
                        {[<ChannelPill channel={channel} active_name={selected_channel} on_select={refresh_channel} /> for channel in channels if channel]}
                    </div>
                </aside>

                <section className="space-y-6">
                    <div className="rounded-3xl border border-border bg-card/80 p-5 shadow-card backdrop-blur">
                        <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                            <div>
                                <div className="text-xs uppercase tracking-[0.25em] text-muted-foreground">Active channel</div>
                                <div className="mt-1 text-2xl font-bold">#{selected_channel}</div>
                            </div>
                            <div className="text-sm text-muted-foreground">Messages and files stay graph-connected to each channel.</div>
                        </div>
                    </div>

                    <div className="rounded-3xl border border-border bg-card/80 p-5 shadow-card backdrop-blur">
                        <div className="flex items-center justify-between gap-3">
                            <div>
                                <div className="text-lg font-semibold">Messages</div>
                                <div className="text-sm text-muted-foreground">Post updates and let the message leaf agent summarize or search them.</div>
                            </div>
                        </div>
                        <div className="mt-5 space-y-3">
                            {[<MessageCard message={message} /> for message in messages if message]}
                        </div>
                        <div className="mt-5 flex flex-col gap-3 md:flex-row">
                            <input className="min-w-0 flex-1 rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/30" value={message_input} placeholder={f"Post a message in #{selected_channel}"} onChange={handle_message_input} />
                            <button className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={send_message}>
                                Send message
                            </button>
                        </div>
                    </div>
                </section>

                <aside className="space-y-6">
                    <div className="rounded-3xl border border-border bg-card/80 p-5 shadow-card backdrop-blur">
                        <div className="text-lg font-semibold">Files</div>
                        <div className="mt-1 text-sm text-muted-foreground">Metadata-first file sharing for a fast hackathon demo.</div>
                        <div className="mt-5 space-y-3">
                            {[<FileCard file={file} /> for file in files if file]}
                        </div>
                    </div>

                    <div className="rounded-3xl border border-border bg-card/80 p-5 shadow-card backdrop-blur">
                        <div className="text-lg font-semibold">Assistant</div>
                        <div className="mt-1 text-sm text-muted-foreground">Try routing prompts like “Find the onboarding PDF in HR” or “Post in engineering that deployment is at 5 PM”.</div>
                        <textarea className="mt-4 min-h-28 w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/30" value={assistant_prompt} onChange={handle_assistant_input} />
                        <div className="mt-4 flex flex-col gap-3 sm:flex-row">
                            <button className="flex-1 rounded-2xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={run_workspace_assistant}>
                                Ask workspace agent
                            </button>
                            <button className="flex-1 rounded-2xl border border-border bg-muted px-4 py-3 text-sm font-semibold text-foreground transition hover:bg-card-hover" onClick={run_channel_assistant}>
                                Ask channel agent
                            </button>
                        </div>
                        <div className="mt-5">
                            <AgentPanel result={assistant_result} />
                        </div>
                    </div>
                </aside>
            </div>
        </div>
    </div>;
}
