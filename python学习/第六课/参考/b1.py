# @预期
# 11
# 2
# True True
# -1
# @结束
line = "2026-09-21 ERROR 磁盘已满"
print(line.find("ERROR"))
print(line.count("-"))
print(line.startswith("2026"), line.endswith("满"))
print(line.find("WARN"))