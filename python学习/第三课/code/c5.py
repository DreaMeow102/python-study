shuZi = [10,20,30,40,50]
partShuZi = (shuZi[ : :-1])
partShuZi[0] = 999
print (partShuZi)
print (shuZi)
# c#里做新切片很麻烦，这个切了之后居然可以直接改,很有意思