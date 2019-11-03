using Soup;

namespace GDiscord { 
    const string url = "https://discordapp.com/api";

    public class Client : Object {
        public string token;

        // Connection stuff
        protected Soup.Session session;
        protected GLib.SocketClient client;
        protected Soup.URI websocket_uri;
        protected Soup.WebsocketConnection connection;
        protected GLib.SocketConnection stream;

        // Heartbeat stuff
        protected Json.Node last_data;

        protected Soup.Message api_call(string path, string method="GET", string body = "", Soup.MessageHeaders? heads = null) {
            Soup.MessageHeaders headers = null;
            Soup.MessageBody msg_body = new Soup.MessageBody();

            if (heads != null) {
                headers = heads;
            } else {
                headers = new Soup.MessageHeaders(Soup.MessageHeadersType.REQUEST);
            }

            headers.append("Authorization", "Bot " + this.token);
            headers.append("User-Agent", "DiscordBot (https://github.com/Appadeia/gdiscord, 0.1)");

            var message = new Soup.Message(method, url + path);
            if (body != "") {
                message.set_request("application/json", Soup.MemoryUse.COPY, body.data);
                headers.append("Content-Type", "application/json");
            }

            //  print(msg_body.length.to_string() + "\n");
            //  message.request_body = msg_body;

            message.request_headers = headers;
            
            session.send_message ( message );

            print("API call:\n");
            print("Path:\t" + path + "\n");
            print("Method:\t" + method + "\n");
            print("Code:\t" + message.status_code.to_string() + "\n");
            print("=========================================\n");
            print((string) message.response_body.flatten().data + "\n");
            print("=========================================\n");

            return message;
        }
        protected Soup.URI get_websocket_gateway() {
            var msg = this.api_call("/gateway");
            var parser = new Json.Parser();

            parser.load_from_data((string) msg.response_body.flatten().data, -1);
            var root = parser.get_root().get_object();
            var url = root.get_string_member("url");

            return new Soup.URI(url + "?v=6&encoding=json");
        }
        protected void init_stream() {
            Resolver resolver = Resolver.get_default();
            List<InetAddress> addressess = resolver.lookup_by_name(this.websocket_uri.get_host(), null);
            InetAddress address = addressess.nth_data(0);

            this.client = new SocketClient();
            this.stream = client.connect(new InetSocketAddress (address, 80));
        }
        protected async void handle_message(int type, Bytes message) {
            var data = (char*) message.get_data();
            var data_str = (string) data;

            var parser = new Json.Parser();
            parser.load_from_data(data_str, -1);
            var root = parser.get_root().get_object();
            var op = root.get_int_member("op");
            if (op == 10) {
                // authentication needed
                // generate authentication
                var build = new Json.Builder();
                build.begin_object();
                    build.set_member_name("op");
                        build.add_int_value(2);
                    build.set_member_name("d");
                    build.begin_object();
                        build.set_member_name("token");
                            build.add_string_value(this.token);
                        build.set_member_name("properties");
                            build.begin_object();
                            build.end_object();
                        build.set_member_name("compress");
                            build.add_boolean_value(false);
                        build.set_member_name("large_threshold");
                            build.add_int_value(250);
                    build.end_object();
                build.end_object();
                Json.Generator generator = new Json.Generator();
                Json.Node gen_root = build.get_root();
                generator.set_root(gen_root);
                // set up the heartbeat as well
                var data_obj = root.get_object_member("d");
                var timeout = data_obj.get_int_member("heartbeat_interval");
                GLib.Timeout.add((uint) timeout, () => {
                    this.heartbeat();
                    return true;
                }, GLib.Priority.DEFAULT);
                GLib.Timeout.add(2000, () => {
                    this.send_message_to_user(249987062084665344, "This message was brought to you by GObject");
                    return false;
                }, GLib.Priority.DEFAULT);
                print("Heartbeat: " + timeout.to_string() + "\n");

                // send the authentication
                this.connection.send_text((string) generator.to_data(null));
            } else if (op == 0) {
                // regular message
                this.last_data = new Json.Node(Json.NodeType.OBJECT);
                this.last_data.take_object(root.get_object_member("d"));
            } else if (op == 1) {
                this.heartbeat();
            } else if (op == 9) {
                print("invalid session!\n");
            }
        }
        protected async void heartbeat() {
            var build = new Json.Builder();
            build.begin_object(); // {
            build.set_member_name("op"); // "op": ...
                build.add_int_value(1); // "op": 1, // heartbeat operator
            build.set_member_name("d"); // "d": ...
                build.add_value(this.last_data);
            build.end_object();
            Json.Generator generator = new Json.Generator();
            Json.Node gen_root = build.get_root();
            generator.set_root(gen_root);
            string str = generator.to_data(null);
            this.connection.send_text(str);
        }
        protected void error(Error error) {
            print(error.message);
        }

        public Client(string token) {
            this.session = new Soup.Session();
            this.token = token;
        }
        public async void send_message_to_user(int64 id, string content) {
            var body = new Soup.MessageBody();
            var chan_response = this.api_call("/users/@me/channels", "POST", "{\"recipient_id\":" + id.to_string() + "}");

            var parser = new Json.Parser();

            parser.load_from_data((string) chan_response.response_body.flatten().data, -1);
            var json_root = parser.get_root().get_object();

            var chan_id = json_root.get_string_member("id");
            
            this.api_call(@"/channels/$chan_id/messages", "POST", @"{\"content\": \"$content\"}");
        }
        public async void run() {
            this.websocket_uri = this.get_websocket_gateway();
            this.init_stream();
            var msg = new Soup.Message.from_uri("GET", this.websocket_uri);
            this.connection = yield this.session.websocket_connect_async(msg, null, null, null);
            this.connection.max_incoming_payload_size = uint64.MAX;

            this.connection.message.connect((t, m) => {
                this.handle_message(t,m);
            });
            this.connection.error.connect((e) => {
                this.error(e);
            });
        }
    }
}