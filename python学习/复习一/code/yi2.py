name = ["alice","bob","carol"]
a = name[0]
b = a[0]
print (b)
c = name[1]
d = c[0:2]
print (d)
e = name[-1]
f = e[2: ]
print (f)
g = a + c + e
print (g)
# 虽然一坨，但是很顺——且正确。这个就应该没问题了。输出也是字符串。
# 肯定有更好的实现方式，但这个是我目前第一时间想到的。