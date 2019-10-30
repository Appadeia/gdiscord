incdir = include_directories('../lib')

executable(
    'gdiscord-test',

    'test.vala',

    link_with: [libgdiscord],
    dependencies: [libgdiscord_deps],
    include_directories: incdir,
    install: true
)