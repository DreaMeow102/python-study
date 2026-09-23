# @预期
# True
# False
# 找到了
# @结束
line = "abc"
print(bool(line.find("z")))
print(bool(line.find("a")))
if line.find("z"):
    print("找到了")
else:
    print("没找到")