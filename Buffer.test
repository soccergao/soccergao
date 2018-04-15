缓冲区(buffer)

位置(position)
  缓冲区中将读取或写入的下一个位置。这个位置值从0开始计，最大值等于缓冲区的大小。可以从下面两个方法获取和设置：
    public final int position()
    public final Buffer position(int newPosition)
    
容量(capacity)
  缓冲区可以保存的元素的最大数目。容量值在创建缓冲区时设置，此后不能改变。可以用一下方法读取：
    public final int capacity()
    
限度(limit)
  缓冲区中可访问数据的末尾位置。只要不改变限度，就无法读/写超过这个位置的数据，即使缓冲区有更大的容量也没有用。限度可以用下面两个方法获取和设置：
    public final int limit()
    public final Buffer limit(int newLimit)
    
标记(mark)
  缓冲区中客户端指定的索引。通过调用mark()可以将标记设置为当前位置。调用reset()可以将当前位置设置为所标记的位置：
    public final Buffer mark()
    public final Buffer reset()
  
