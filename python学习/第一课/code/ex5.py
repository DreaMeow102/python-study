#print ("hello)
# File "D:\studydemo\python学习\code\ex5.py", line 1
#     print ("hello)
#            ^
# SyntaxError: unterminated string literal (detected at line 1)
# 终端的报错其实能直接打印出来，SyntaxError应该是缺少字符串，不过只是我的推测

#if (1<0):
#print ("error")
#  File "D:\studydemo\python学习\code\ex5.py", line 9
#     print ("error")
#     ^^^^^
# IndentationError: expected an indented block after 'if' statement on line 8
# 同上，终端的报错实际上能打出来，但这边就能很清晰的从读英文中看出是缩进塌了，有报出是第几行的问题

# print(“你好”)
#  File "D:\studydemo\python学习\code\ex5.py", line 16
#     print(“你好”)
#           ^
# SyntaxError: invalid character '“' (U+201C)
# 这里直接报码了，不识别。