# @预期
# 姓名  分数
# 张三  88
# 李四  95
# 王五  71
# 平均  84.67
# @结束
raw = "  张三:  88 , 李四:95,  王五 : 71 "
items = raw.split(",")
names = []
scores = []
for it in items:
    p = it.split(":")
    names.append(p[0].strip())
    scores.append(int(p[1].strip()))
print("姓名  分数")
for i in range(len(names)):
    print(f"{names[i]}  {scores[i]}")
print(f"平均  {sum(scores) / len(scores):.2f}")