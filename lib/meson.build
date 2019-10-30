gdiscord_sources = [
    'client/client.vala'
]

gdiscord_gi_name = 'GDiscord'
gdiscord_gi_version = '1.0'

gdiscord_gi = gdiscord_gi_name + '-' + gdiscord_gi_version
gdiscord_gir = gdiscord_gi + '.gir'
gdiscord_typelib = gdiscord_gi + '.typelib'

include_dir = join_paths(
    get_option('prefix'),
    get_option('includedir'),
    'gdiscord'
)

libgdiscord = library(
    'gdiscord',

    gdiscord_sources,

    dependencies: [
        libgdiscord_deps
    ],

    vala_header: 'gdiscord.h',
    vala_vapi: 'gdiscord.vapi',
    vala_gir: gdiscord_gir,

    version: meson.project_version(),
    install: true,
    install_dir: [true, include_dir, true, true]
)

g_ir_compiler = find_program('g-ir-compiler')
custom_target(
    gdiscord_typelib,
    command: [
        g_ir_compiler,
        '--shared-library',
        '@PLAINNAME@',
        '--output',
        '@OUTPUT@',
        join_paths(meson.current_build_dir(), gdiscord_gir),
    ],
    input: libgdiscord,
    output: gdiscord_typelib,
    depends: libgdiscord,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0')
)

gdiscord_pc = pkgconfig.generate(
    libgdiscord,
    name: 'gdiscord',
    requires: libgdiscord_deps,
    subdirs: ['gdiscord'],
    description: 'GObject library for Discord',
    version: meson.project_version()
)