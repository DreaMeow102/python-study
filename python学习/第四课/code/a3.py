print (bool (0)) #false
print (bool (1)) #true
print (bool ("")) #false
print (bool ("abc")) #true
print (bool ([])) #false
print (bool ([1,2])) # true
# **做完记住这张表**：`False` / `None` / `0` / `""` / `[]` 都算假，其余算真。
# 其实我不认同上述说法，我觉得可以不用死记，只要是没装东西、数字本身代表“没有”，意义本身代表“否定”，那就是假值了。
