import re

with open('lib/modules/pages/salon_details_screen.dart', 'r') as f:
    content = f.read()

# Fix the end of `_packageCard`
old_end = """              ],
            ),

}"""
new_end = """              ],
            ),
          ),
        ],
      ),
    );
  }
}"""
content = content.replace(old_end, new_end)

with open('lib/modules/pages/salon_details_screen.dart', 'w') as f:
    f.write(content)
