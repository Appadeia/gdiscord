static int main(string[] args) {
    var loop = new MainLoop();
    
    var client = new GDiscord.Client("ood", loop.get_context());
    client.run();

    loop.run();

    return 0;
}