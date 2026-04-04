sv import from .api {
    bootstrap_demo as api_bootstrap_demo,
    list_organizations as api_list_organizations,
    get_organization_info as api_get_organization_info,
    list_organization_channels as api_list_organization_channels,
    list_organization_members as api_list_organization_members,
    list_messages as api_list_messages,
    create_message as api_create_message,
    list_files as api_list_files,
    ask_organization as api_ask_organization,
    ask_channel as api_ask_channel,
    get_agent_tree as api_get_agent_tree
}

def OrgCard(org: any, on_select: any) -> JsxElement {
    def handle_click() -> None {
        on_select(org.name);
    }
    return <button className="group rounded-3xl border border-border bg-card p-6 text-left shadow-card transition hover:-translate-y-0.5 hover:bg-card-hover" onClick={handle_click}>
        <div className="flex items-start justify-between gap-4">
            <div>
                <div className="text-xs uppercase tracking-[0.25em] text-primary">Organization</div>
                <div className="mt-2 text-2xl font-bold text-foreground">{org.name}</div>
            </div>
            <div className="rounded-full border border-border px-3 py-1 text-xs text-muted-foreground">{org.member_count} members</div>
        </div>
        <p className="mt-4 text-sm leading-6 text-muted-foreground">{org.description}</p>
        <div className="mt-5 flex gap-3 text-xs text-muted-foreground">
            <span className="rounded-full bg-muted px-3 py-1">{org.channel_count} channels</span>
            <span className="rounded-full bg-primary/10 px-3 py-1 text-primary">Open workspace</span>
        </div>
    </button>;
}

def ChannelCard(channel: any, on_select: any) -> JsxElement {
    def handle_click() -> None {
        on_select(channel.name);
    }
    return <button className="w-full rounded-2xl border border-border bg-card p-4 text-left shadow-soft transition hover:bg-card-hover" onClick={handle_click}>
        <div className="flex items-center justify-between gap-3">
            <div>
                <div className="text-base font-semibold text-foreground">#{channel.name}</div>
                <div className="mt-1 text-sm text-muted-foreground">{channel.topic}</div>
            </div>
            <div className="rounded-full border border-border px-2 py-1 text-[10px] uppercase tracking-[0.2em] text-muted-foreground">{channel.visibility}</div>
        </div>
    </button>;
}

def MessageCard(message: any) -> JsxElement {
    return <div className="rounded-2xl border border-border bg-card p-4 shadow-soft">
        <div className="flex items-center justify-between gap-3">
            <div className="text-sm font-semibold text-foreground">{message.author}</div>
            <div className="text-xs text-muted-foreground">{message.created_at}</div>
        </div>
        <div className="mt-3 text-sm leading-6 text-foreground/90">{message.content}</div>
    </div>;
}

def FileCard(file: any) -> JsxElement {
    return <div className="rounded-2xl border border-border bg-card p-4 shadow-soft">
        <div className="flex items-start justify-between gap-3">
            <div>
                <div className="text-sm font-semibold text-foreground">{file.filename}</div>
                <div className="mt-1 text-xs text-muted-foreground">Uploaded by {file.uploaded_by}</div>
            </div>
            <a className="rounded-full border border-border px-3 py-1 text-xs text-primary hover:bg-primary/10" href={file.url_or_path} target="_blank">Open</a>
        </div>
        <div className="mt-3 text-sm text-foreground/85">{file.summary}</div>
        <div className="mt-3 flex flex-wrap gap-2">
            {[<span className="rounded-full bg-muted px-2.5 py-1 text-[11px] text-muted-foreground">{tag}</span> for tag in file.tags if tag]}
        </div>
    </div>;
}

def AgentTree(tree: any) -> JsxElement {
    if not tree or not tree.root {
        return <div className="rounded-2xl border border-dashed border-border p-4 text-sm text-muted-foreground">Select an organization to load the agent tree.</div>;
    }
    return <div className="space-y-4">
        <div className="rounded-2xl border border-primary/30 bg-primary/10 p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-primary">Root assistant</div>
            <div className="mt-1 text-sm font-semibold text-foreground">{tree.root.name}</div>
        </div>
        <div className="space-y-4">
            {[
                <div className="agent-branch rounded-2xl border border-border bg-card p-4 shadow-soft">
                    <div className="text-sm font-semibold text-foreground">{child.name}</div>
                    <div className="mt-1 text-xs text-muted-foreground">Channel agent for #{child.channel}</div>
                    <div className="mt-3 grid gap-2">
                        {[
                            <div className="rounded-xl border border-border bg-muted/60 px-3 py-2 text-xs text-foreground">{leaf.name}</div>
                            for leaf in child.children if leaf
                        ]}
                    </div>
                </div>
                for child in tree.root.children if child
            ]}
        </div>
    </div>;
}

def AssistantPanel(props: dict) -> JsxElement {
    assistant_open = props.assistant_open;
    assistant_prompt = props.assistant_prompt;
    assistant_result = props.assistant_result;
    tree = props.agent_tree;
    on_prompt_change = props.on_prompt_change;
    on_toggle = props.on_toggle;
    on_org_ask = props.on_org_ask;
    on_channel_ask = props.on_channel_ask;
    selected_org = props.selected_org;
    selected_channel = props.selected_channel;

    if not assistant_open {
        return <button className="fixed right-4 top-1/2 z-20 rounded-l-2xl rounded-r-md border border-border bg-card px-3 py-6 text-xs font-semibold text-foreground shadow-card" onClick={on_toggle}>Open assistant</button>;
    }

    return <aside className="sticky top-4 h-[calc(100vh-2rem)] overflow-y-auto rounded-3xl border border-border bg-card/95 p-5 shadow-card backdrop-blur">
        <div className="flex items-center justify-between gap-3">
            <div>
                <div className="text-xs uppercase tracking-[0.25em] text-primary">Assistant</div>
                <div className="mt-1 text-lg font-semibold text-foreground">Root + channel agents</div>
            </div>
            <button className="rounded-full border border-border px-3 py-1 text-xs text-muted-foreground hover:bg-card-hover" onClick={on_toggle}>Collapse</button>
        </div>
        <div className="mt-4 rounded-2xl bg-muted/60 p-3 text-xs text-muted-foreground">{selected_org} / #{selected_channel}</div>
        <textarea className="mt-4 min-h-28 w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/30" value={assistant_prompt} onChange={on_prompt_change} />
        <div className="mt-4 grid gap-3">
            <button className="rounded-2xl bg-primary px-4 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={on_org_ask}>Ask org assistant</button>
            <button className="rounded-2xl border border-border bg-muted px-4 py-3 text-sm font-semibold text-foreground transition hover:bg-card-hover" onClick={on_channel_ask}>Ask channel assistant</button>
        </div>
        <div className="mt-5 rounded-2xl border border-border bg-background/60 p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-muted-foreground">Route result</div>
            <div className="mt-3 space-y-2 text-sm text-foreground/90">
                <div><span className="font-semibold text-foreground">Organization:</span> {assistant_result.selected_organization or selected_org}</div>
                <div><span className="font-semibold text-foreground">Channel:</span> #{assistant_result.selected_channel or selected_channel}</div>
                <div><span className="font-semibold text-foreground">Domain:</span> {assistant_result.selected_domain or "messages"}</div>
                <div><span className="font-semibold text-foreground">Root:</span> {assistant_result.general_agent or "Ready to route."}</div>
                <div><span className="font-semibold text-foreground">Channel:</span> {assistant_result.channel_agent or "Waiting for a prompt."}</div>
                <div><span className="font-semibold text-foreground">Leaf:</span> {assistant_result.leaf_agent or "No leaf action yet."}</div>
            </div>
        </div>
        <div className="mt-5">
            <div className="mb-3 text-xs uppercase tracking-[0.2em] text-muted-foreground">Agent tree</div>
            <AgentTree tree={tree} />
        </div>
    </aside>;
}

def:pub AppShell() -> JsxElement {
    has organizations: list = [];
    has selected_org: str = "";
    has selected_channel: str = "general";
    has organization_info: dict = {};
    has organization_channels: list = [];
    has organization_members: list = [];
    has messages: list = [];
    has files: list = [];
    has assistant_prompt: str = "Summarize what happened in this organization today";
    has assistant_result: dict = {};
    has assistant_open: bool = True;
    has agent_tree: dict = {};
    has active_tab: str = "messages";
    has current_view: str = "landing";
    has message_input: str = "";
    has loading: bool = True;
    has error_text: str = "";

    async def load_org(org_name: str) -> None {
        selected_org = org_name;
        organization_info = await api_get_organization_info(org_name) or {};
        organization_channels = await api_list_organization_channels(org_name) or [];
        organization_members = await api_list_organization_members(org_name) or [];
        agent_tree = await api_get_agent_tree(org_name) or {};
        if len(organization_channels) > 0 {
            selected_channel = organization_channels[0].name;
        } else {
            selected_channel = "general";
        }
    }

    async def load_channel(org_name: str, channel_name: str) -> None {
        selected_org = org_name;
        selected_channel = channel_name;
        messages = await api_list_messages(org_name, channel_name) or [];
        files = await api_list_files(org_name, channel_name) or [];
        agent_tree = await api_get_agent_tree(org_name) or {};
    }

    async can with entry {
        try {
            await api_bootstrap_demo();
            organizations = await api_list_organizations() or [];
            if len(organizations) > 0 {
                await load_org(organizations[0].name);
            }
            loading = False;
        } catch e {
            error_text = str(e);
            loading = False;
        }
    }

    def handle_prompt_change(e: any) -> None {
        assistant_prompt = e.target.value;
    }

    def handle_message_input(e: any) -> None {
        message_input = e.target.value;
    }

    def toggle_assistant() -> None {
        assistant_open = not assistant_open;
    }

    async def open_org(org_name: str) -> None {
        await load_org(org_name);
        current_view = "organization";
        active_tab = "messages";
    }

    async def open_channel(channel_name: str) -> None {
        await load_channel(selected_org, channel_name);
        current_view = "channel";
    }

    async def go_to_org() -> None {
        await load_org(selected_org);
        current_view = "organization";
    }

    def go_to_landing() -> None {
        current_view = "landing";
    }

    async def send_message() -> None {
        if not message_input.strip() or not selected_org or not selected_channel {
            return;
        }
        await api_create_message(selected_org, selected_channel, "You", message_input.strip());
        message_input = "";
        messages = await api_list_messages(selected_org, selected_channel) or [];
        active_tab = "messages";
    }

    async def run_org_assistant() -> None {
        if not assistant_prompt.strip() or not selected_org {
            return;
        }
        assistant_result = await api_ask_organization(selected_org, assistant_prompt.strip()) or {};
        if assistant_result.selected_channel {
            await load_channel(selected_org, assistant_result.selected_channel);
            current_view = "channel";
            active_tab = assistant_result.selected_domain or "messages";
        }
    }

    async def run_channel_assistant() -> None {
        if not assistant_prompt.strip() or not selected_org or not selected_channel {
            return;
        }
        assistant_result = await api_ask_channel(selected_org, selected_channel, assistant_prompt.strip()) or {};
        await load_channel(selected_org, selected_channel);
        active_tab = assistant_result.selected_domain or active_tab;
    }

    if loading {
        return <div className="min-h-screen bg-background px-6 py-10 text-foreground"><div className="mx-auto max-w-7xl rounded-3xl border border-border bg-card p-10 shadow-card">Loading organizations...</div></div>;
    }

    if error_text {
        return <div className="min-h-screen bg-background px-6 py-10 text-foreground"><div className="mx-auto max-w-4xl rounded-3xl border border-destructive/40 bg-card p-10 shadow-card"><div className="text-xl font-bold">App error</div><div className="mt-3 text-sm text-muted-foreground">{error_text}</div></div></div>;
    }

    return <div className="min-h-screen bg-background px-4 py-4 text-foreground md:px-6">
        <div className="mx-auto grid max-w-[1600px] gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
            <main className="space-y-6">
                <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card backdrop-blur">
                    <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
                        <div>
                            <div className="text-xs uppercase tracking-[0.3em] text-primary">Jac organization workspace</div>
                            <h1 className="mt-2 text-3xl font-extrabold tracking-tight">Multi-organization collaboration hub</h1>
                            <p className="mt-2 max-w-3xl text-sm text-muted-foreground">Browse organizations, open channels, send messages, review files, and route requests through a graph-native assistant tree.</p>
                        </div>
                        <div className="rounded-2xl border border-border bg-muted/60 px-4 py-3 text-sm text-muted-foreground">Current view: {current_view}</div>
                    </div>
                </div>

                {current_view == "landing" ?
                    <section className="space-y-5">
                        <div>
                            <div className="text-2xl font-bold">Your organizations</div>
                            <div className="mt-1 text-sm text-muted-foreground">Choose an organization to open its channels, members, and assistant tree.</div>
                        </div>
                        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
                            {[<OrgCard org={org} on_select={open_org} /> for org in organizations if org]}
                        </div>
                    </section>
                : <span />}

                {current_view == "organization" ?
                    <section className="space-y-6">
                        <div className="flex flex-wrap gap-3">
                            <button className="rounded-2xl border border-border bg-card px-4 py-2 text-sm hover:bg-card-hover" onClick={go_to_landing}>← Back to organizations</button>
                        </div>
                        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
                            <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card">
                                <div className="text-xs uppercase tracking-[0.25em] text-primary">Organization page</div>
                                <h2 className="mt-2 text-3xl font-bold">{organization_info.name}</h2>
                                <p className="mt-3 text-sm leading-6 text-muted-foreground">{organization_info.description}</p>
                                <div className="mt-5 flex flex-wrap gap-3 text-sm">
                                    <span className="rounded-full bg-muted px-3 py-1">{organization_info.member_count} members</span>
                                    <span className="rounded-full bg-muted px-3 py-1">{organization_info.channel_count} channels</span>
                                </div>
                                <div className="mt-8">
                                    <div className="text-lg font-semibold">Channels</div>
                                    <div className="mt-4 grid gap-3">
                                        {[<ChannelCard channel={channel} on_select={open_channel} /> for channel in organization_channels if channel]}
                                    </div>
                                </div>
                            </div>
                            <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card">
                                <div className="text-lg font-semibold">Members summary</div>
                                <div className="mt-1 text-sm text-muted-foreground">People currently in this organization.</div>
                                <div className="mt-4 space-y-3">
                                    {[
                                        <div className="rounded-2xl border border-border bg-muted/50 px-4 py-3">
                                            <div className="text-sm font-semibold text-foreground">{member.name}</div>
                                            <div className="text-xs text-muted-foreground">{member.role}</div>
                                        </div>
                                        for member in organization_members if member
                                    ]}
                                </div>
                            </div>
                        </div>
                    </section>
                : <span />}

                {current_view == "channel" ?
                    <section className="space-y-6">
                        <div className="flex flex-wrap gap-3">
                            <button className="rounded-2xl border border-border bg-card px-4 py-2 text-sm hover:bg-card-hover" onClick={go_to_landing}>← Organizations</button>
                            <button className="rounded-2xl border border-border bg-card px-4 py-2 text-sm hover:bg-card-hover" onClick={go_to_org}>← {selected_org}</button>
                        </div>
                        <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card">
                            <div className="text-xs uppercase tracking-[0.25em] text-primary">Channel page</div>
                            <h2 className="mt-2 text-3xl font-bold">{selected_org} / #{selected_channel}</h2>
                            <div className="mt-5 flex gap-3">
                                <button className={("rounded-2xl px-4 py-2 text-sm font-semibold " + ("bg-primary text-primary-foreground" if active_tab == "messages" else "border border-border bg-card hover:bg-card-hover"))} onClick={lambda : any -> None { active_tab = "messages"; }}>Messages</button>
                                <button className={("rounded-2xl px-4 py-2 text-sm font-semibold " + ("bg-primary text-primary-foreground" if active_tab == "files" else "border border-border bg-card hover:bg-card-hover"))} onClick={lambda : any -> None { active_tab = "files"; }}>Files</button>
                            </div>
                        </div>

                        {active_tab == "messages" ?
                            <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card">
                                <div className="text-lg font-semibold">Messages</div>
                                <div className="mt-1 text-sm text-muted-foreground">Send and receive updates from people in this organization.</div>
                                <div className="mt-5 space-y-3">
                                    {[<MessageCard message={message} /> for message in messages if message]}
                                </div>
                                <div className="mt-5 flex flex-col gap-3 md:flex-row">
                                    <input className="min-w-0 flex-1 rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/30" value={message_input} placeholder={"Send a message to #" + selected_channel} onChange={handle_message_input} />
                                    <button className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={send_message}>Send message</button>
                                </div>
                            </div>
                        : <div className="rounded-3xl border border-border bg-card/80 p-6 shadow-card">
                                <div className="text-lg font-semibold">Files</div>
                                <div className="mt-1 text-sm text-muted-foreground">Shared file records for this channel.</div>
                                <div className="mt-5 grid gap-3">
                                    {[<FileCard file={file} /> for file in files if file]}
                                </div>
                            </div>}
                    </section>
                : <span />}
            </main>

            <AssistantPanel props={{
                "assistant_open": assistant_open,
                "assistant_prompt": assistant_prompt,
                "assistant_result": assistant_result,
                "agent_tree": agent_tree,
                "on_prompt_change": handle_prompt_change,
                "on_toggle": toggle_assistant,
                "on_org_ask": run_org_assistant,
                "on_channel_ask": run_channel_assistant,
                "selected_org": selected_org,
                "selected_channel": selected_channel
            }} />
        </div>
    </div>;
}
