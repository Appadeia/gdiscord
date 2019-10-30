using Soup;

namespace GDiscord { 
    const string url = "https://discordapp.com/api";

    public class Client : Object {
        public string token;
        protected Soup.Session session;
        protected GLib.SocketClient client;
        protected Soup.URI websocket_uri;
        protected Soup.WebsocketConnection connection;
        protected GLib.SocketConnection stream;
        protected GLib.MainContext ctxt;

        protected Soup.Message api_call(string path) {
            var message = new Soup.Message("GET", url + path);
            
            session.send_message ( message );
            
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
        protected void handle_message(int type, Bytes message) {
            stdout.printf((string) message);
        }
        public Client(string token, GLib.MainContext ctxt) {
            this.ctxt = ctxt;
            this.session = new Soup.Session();
            this.token = token;
        }
        public void run() {
            this.websocket_uri = this.get_websocket_gateway();
            this.init_stream();
            this.connection = new Soup.WebsocketConnection(this.stream, this.websocket_uri, Soup.WebsocketConnectionType.CLIENT, null, null);
            this.connection.message.connect((t, m) => {
                this.handle_message(t,m);
            });
        }
    }
}