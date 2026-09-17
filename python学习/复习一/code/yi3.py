scores = [88,92,75,96,81]
scores[2] = 85
scores.remove (min(scores))
print(scores)
print(f"人数 {len(scores)}")
# print(f"平均 {sum(int(scores))/len(scores)}")
#   File "D:\studydemo\python学习\复习一\code\yi3.py", line 6, in <module>
#     print(f"平均 {sum(int(scores))/len(scores)}")
#                       ~~~^^^^^^^^
# TypeError: int() argument must be a string, a bytes-like object or a real number, not 'list'
# 忘了点东西导致的。其实本质已经是整数组了。
print(f"平均 {sum(scores)/len(scores)}")