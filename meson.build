project(
    'gdiscord',
    'vala', 'c',
    version: '0.1'
)

pkgconfig = import('pkgconfig')

libgdiscord_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('libsoup-2.4'),
    dependency('json-glib-1.0')
]

subdir('lib')
subdir('examples')