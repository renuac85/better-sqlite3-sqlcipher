# ===
# This configuration defines options specific to compiling SQLite3 itself.
# Compile-time options are loaded by the auto-generated file "defines.gypi".
# The --sqlite3 option can be provided to use a custom amalgamation instead.
# ===

{
  'includes': ['common.gypi'],
  'targets': [
    {
      'target_name': 'locate_sqlite3',
      'type': 'none',
      'hard_dependency': 1,
      'actions': [{
        'action_name': 'extract_sqlite3',
        'inputs': ['sqlite3.tar.gz'],
        'outputs': [
          '<(SHARED_INTERMEDIATE_DIR)/sqlite3/sqlite3.c',
          '<(SHARED_INTERMEDIATE_DIR)/sqlite3/sqlite3.h',
          '<(SHARED_INTERMEDIATE_DIR)/sqlite3/sqlite3ext.h',
        ],
        'conditions': [
          ['OS == "win"', {
            'outputs': [
              '<(SHARED_INTERMEDIATE_DIR)/sqlite3/>(openssl_root)/libcrypto.a',
            ],
          }],
        ],
        'action': ['node', 'extract.js', '<(SHARED_INTERMEDIATE_DIR)/sqlite3'],
      }],
    },
    {
      'target_name': 'copy_dll',
      'type': 'none',
      'dependencies': ['locate_sqlite3'],
      'conditions': [
        ['OS == "win"', {
          'copies': [{
            'files': [
              '<(SHARED_INTERMEDIATE_DIR)/sqlite3/>(openssl_root)/libcrypto.a',
            ],
            'destination': '<(PRODUCT_DIR)',
          }],
        }],
      ],
    },
    {
      'target_name': 'sqlite3',
      'type': 'static_library',
      'dependencies': ['locate_sqlite3', 'copy_dll'],
      'sources': ['<(SHARED_INTERMEDIATE_DIR)/sqlite3/sqlite3.c'],
      'include_dirs': [
        '<(SHARED_INTERMEDIATE_DIR)/sqlite3/',
        '<(SHARED_INTERMEDIATE_DIR)/sqlite3/openssl-include',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '<(SHARED_INTERMEDIATE_DIR)/sqlite3/',
          '<(SHARED_INTERMEDIATE_DIR)/sqlite3/openssl-include',
        ],
      },
      'cflags': ['-std=c99', '-w'],
      'xcode_settings': {
        'OTHER_CFLAGS': ['-std=c99'],
        'WARNING_CFLAGS': ['-w'],
      },
      'includes': ['defines.gypi'],
      'conditions': [
        ['OS == "win"', {
          'defines': [
            'WIN32'
          ],
          'link_settings': {
            'libraries': [
              '-llibcrypto.a',
              '-lws2_32.lib',
            ],
            'library_dirs': [
              '<(SHARED_INTERMEDIATE_DIR)/sqlite3/>(openssl_root)'
            ]
          }
        },
        'OS == "mac"', {
          'link_settings': {
            'libraries': [
              # This statically links libcrypto, whereas -lcrypto would dynamically link it
              '<(SHARED_INTERMEDIATE_DIR)/sqlite3/OpenSSL-macOS/libcrypto.a'
            ]
          }
        },
        { # Linux
          'link_settings': {
            'libraries': [
              # This statically links libcrypto, whereas -lcrypto would dynamically link it
              '<(SHARED_INTERMEDIATE_DIR)/sqlite3/OpenSSL-Linux/libcrypto.a'
            ]
          }
        }],
      ],
      'configurations': {
        'Debug': {
          'msvs_settings': { 'VCCLCompilerTool': { 'RuntimeLibrary': 1 } }, # static debug
        },
        'Release': {
          'msvs_settings': { 'VCCLCompilerTool': { 'RuntimeLibrary': 0 } }, # static release
        },
      },
    },
  ],
}
