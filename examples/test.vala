static int main(string[] args) {
    var loop = new MainLoop();
    
    if (args[1] == null) {
        print("You forgot to pass a token!\n");
        return 1;
    }
    var client = new GDiscord.Client(args[1]);
    client.run();

    loop.run();

    return 0;
}