word = input("请输入一个词：")
a = word[ : :-1]

if word == a:
    print (f"{word}这段词是回文。")
else:
    print (f"{word}这段词不是回文。")

# 这段莫名其妙很顺？