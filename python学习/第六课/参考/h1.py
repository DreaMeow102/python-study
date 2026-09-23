# @预期
# True
# 9
# C:\new\test
# True
# 11 11
# @结束
bad = "C:\new\test"
print(bad == "C:" + chr(10) + "ew" + chr(9) + "est")
print(len(bad))
good1 = r"C:\new\test"
good2 = "C:\\new\\test"
print(good1)
print(good1 == good2)
print(len(good1), len(good2))