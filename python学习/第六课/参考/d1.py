# @预期
# ['张', '三', '20', '北京']
# ['a', 'b', '', 'c']
# ['a', 'b', 'c,d']
# @结束
line = "  张 三   20  北京  "
print(line.split())
print("a,b,,c".split(","))
print("a,b,c,d".split(",", 2))