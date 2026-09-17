original = [1,2,3,4,5]
copy1 = original[ : ]
copy1[0] = 99
print(original)
print(copy1)
#这部分顺到啥都没看，一路到底

same = original
#坏了，经不得夸，看一眼怎么添加。我只记得个end了。
#append()
same.append(6)
print(original)
print(same)

#除了突然忘记加东西以外，基本没什么问题
