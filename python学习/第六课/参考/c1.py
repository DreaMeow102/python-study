# @预期
# [Hello, World]
# hello, world
# Hello, Python
# [  HELLO, WORLD  ]
# @结束
s = "  Hello, World  "
print(f"[{s.strip()}]")
print(s.strip().lower())
print(s.strip().replace("World", "Python"))
print(f"[{s.upper()}]")