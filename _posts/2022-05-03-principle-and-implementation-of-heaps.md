---
layout: post
title: 堆的原理和实现
date: 2022-05-03 19:43 +0800
categories: [Bottom Layer Knowledge] 
tags: [Data Structure]
---
# 堆
堆这种数据结构，有很多的实现，比如：最大堆，最小堆，斐波那锲堆，左派堆，斜堆等。从孩子节点的个数上还可以分为二叉堆，N叉堆等。本文我们从最大二叉堆堆入手看看堆究竟是什么

## 什么是堆
我们先看看它的定义

- 堆是一种完全二叉树（不是平衡二叉树，也不是二分搜索树哦）
- 堆要求孩子节点要小于等于父亲节点（如果是最小堆则大于等于其父亲节点）

满足以上两点性质即可成为一棵合格的堆数据结构。我们解读一下上面的两点性质

- 堆是一种完全二叉树，要注意堆是一种建立在二叉树上的数据结构，不同于AVL或者红黑树是建立在二分搜索树上的数据结构。
- 堆要求孩子节点要大于等于父亲节点，该定义是针对的最大堆。对于最小堆，孩子节点小于或者等于其父亲节点。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822143009280-1059868436.png)

如上所示，只有图1是合格的最大堆，图2不满足父节点大于或者等于孩子节点的性质。图3不满足完全二叉树的性质。

## 堆的存储结构
前面我们说堆是一个完全二叉树，其中一种在合适不过的存储方式就是数组。首先从下图看一下用数组表示堆的可行性。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822150256478-1445219636.png)

看了上图，说明数组确实是可以表示一个二叉堆的。使用数组来存储堆的节点信息，有一种天然的优势那就是节省内存空间。因为数组占用的是连续的内存空间，相对来说对于散列存储的结构来说，数组可以节省连续的内存空间，不会将内存打乱。

接下来看看数组到二叉堆的下标表示。将数组的索引设为 i。则：

- 左孩子找父节点：`parent（i）= （i - 1）/2`。比如2元素的索引为5，其父亲节点4的下标parent（2）= （5 - 1）/2 = 2；

- 右孩子找父节点：`parent（i）= （i-2）/ 2`。比如0元素找父节点 （6-2）/2= 2；

- 其实可以将上面的两种方法合并成一个，即 `parent（i）= （i - 1）/2` ；从java语法出发大家可以发现，整数相除得到的就是省略了小数位的。所以。。。你懂得。

同理

- 父节点找左孩子：`leftChild(i)= parent(i)* 2 + 1`。

- 父节点找右孩子：`rightChild(i) = parent(i)*2 + 2`。

# 最大二叉堆的实现
## 构建基础代码
上面分析了数组作为堆存储结构的可行性分析。接下来我们通过数组构建一下堆的基础结构
```java
/**
  * 描述：最大堆
  **/
 public class MaxHeap<E extends Comparable<E>> {
     //使用数组存储
     private Array<E> data;
     public MaxHeap(){
         data = new Array<>();
     }
     public MaxHeap(int capacity){
         data = new Array<>(capacity);
     }
     public int size(){
         return this.data.getSize();
     }
     public boolean isEmpty(){
         return this.data.isEmpty();
     }
 
     /**
      * 根据当前节点索引 index 计算其父节点的 索引
      * @param index
      * @return
      */
     private int parent(int index) {
         if(index ==0){
             throw new IllegalArgumentException("该节点为根节点");
         }
         return (index - 1) / 2;//这里为什么不分左右？因为java中 / 运算符只保留整数位。
     }
 
    /**
     * 返回索引为 index 节点的左孩子节点的索引
     * @param index
     * @return
     */
    private int leftChild(int index){
        return index*2 + 1;
    }

    /**
     * 返回索引为 index 节点的右孩子节点的索引
     * @param index
     * @return
     */
    private int rightChild(int index){
        return index*2 + 2;
    }
}
```

## 插入和上浮 sift up

堆中插入元素意味着该堆的性质可能遭到破坏，所以这是如同向AVL中插入元素后需要再平衡是一个道理，需要调整堆中元素的位置，使之重新满足堆的性质。在最大二叉堆中，要堆化一个元素，需要向上查找，找到它的父节点，大于父节点则交换两个元素，重复该过程直到每个节点都满足堆的性质为止。这个过程我们称之为上浮操作。下面我们用图例描述一下这个过程：

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822160151706-1386885183.png)

如上图5所示，我们向该堆中插入一个元素15。在数组中位于数组尾部。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822160235595-1590758439.png)

如图6所示，向上查找，发现15大于它的父节点，所以进行交换。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822160750028-432052011.png)

如图7所示，继续向上查找，发现仍大于其父节点14。继续交换。

然后还会继续向上查找，发现小于其父节点19，停止上浮操作。整个二叉堆通过上浮操作维持了其性质。上浮操作的时间复杂度为O(logn)

插入和上浮操作的代码实现很简单，如下所示。

```java
/**
* 向堆中添加元素
* @param e
*/
public void add(E e){
    // 向数组尾部添加元素
    this.data.addLast(e);
    siftUp(data.getSize() - 1);
}

/**
* 上浮操作
* @param k
*/
private void siftUp(int k) {
  // 上浮，如果大于父节点，进行交换
  while(k > 0 && get(k).compareTo(get(parent(k))) > 0){
      data.swap(k, parent(k));
      k = parent(k);
  }
}
```

## 取出堆顶元素和下沉 sift down
上面我们介绍了插入和上浮操作，那删除和下沉操作将不再是什么难题。一般的如果我们取出堆顶元素，我们选择将该数组中的最后一个元素替换堆顶元素，返回堆顶元素，删除最后一个元素。然后再对该元素做下沉操作 sift down。接下来我们通过图示看看一下过程。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822162211163-1593824582.png)

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822162351830-785592047.png)

如上图8所示，将堆顶元素取出，然后让最后一个元素移动到堆顶位置。删除最后一个元素，这时得到图9的结果。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822163041732-279961709.png)

如图10，堆顶的9元素会分别和其左右孩子节点进行比较，选出较大的孩子节点和其进行交换。很明显右孩子17大于左孩子15。即和右孩子进行交换。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-05-03-principle-and-implementation-of-heaps/1635748-20190822163430896-934961142.png)

如图11，9节点继续下沉最终和其左孩子12交换后，再没有孩子节点。此次过程的下沉操作完成。下沉操作的时间复杂度为O(logn)

代码实现仍然是非常简单

```java
/**
* 取出堆中最大元素
* 时间复杂度 O（logn）
* @return
*/
public E extractMax(){
  E ret = findMax();
  this.data.swap(0, (data.getSize() - 1));
  data.removeLast();
  siftDown(0);
  return ret;
}
13 
/**
* 下沉操作
* 时间复杂度 O（logn）
* @param k
*/
public void siftDown(int k){
  while(leftChild(k) < data.getSize()){// 从左节点开始，如果左节点小于数组长度，就没有右节点了
      int j = leftChild(k);
      if(j + 1 < data.getSize() && get(j + 1).compareTo(get(j)) > 0){// 选举出左右节点最大的那个
          j ++;
      }
      if(get(k).compareTo(get(j)) >= 0){// 如果当前节点大于左右子节点，循环结束
          break;
      }
      data.swap(k, j);
      k = j;
  }
}
```

## Replace和Heapify
Replace操作呢其实就是取出堆顶元素然后新插入一个元素。根据我们上面的总结，大家很容易想到。返回堆顶元素后，直接将该元素置于堆顶，然后再进行下沉操作即可。
```java

/**
 * 取出最大的元素，并替换成元素 e
 * 时间复杂度 O（logn）
 * @param e
 * @return
 */
public E replace(E e){
    E ret = findMax();
    data.set(0, e);
    siftDown(0);
    return ret;
}
```
Heapify操作就比较有意思了。Heapify本身的意思为“堆化”，那我们将什么进行堆化呢？根据其存储结构，我们可以将任意一个数组进行堆化。将一个数组堆化？what？一个个向最大二叉堆中插入不就行了？呃，如果这样的话，需要对每一个元素进行一次上浮时间复杂度为O(nlogn)。显然这样做的话，时间复杂度控制的不够理想。有没有更好的方法呢。既然这样说了，肯定是有的。思路就是将一个数组当成一个完全二叉树，然后从最后一个非叶子节点开始逐个对飞叶子节点进行下沉操作。如何找到最后一个非叶子节点呢？这也是二叉堆常问的一个问题。相信大家还记得前面我们说过`parent(i) = (child(i)-1)/2`。这个公式是不分左右节点的哦，自己可以用代码验证一下，在前面的`parent()`方法中也有注释解释了。那么最后一个非叶子节点其实就是 `（(arr.size())/2 - 1）`即可。

```java
 /**
  * Heapify
  * @param arr
  */
 public MaxHeap(E[] arr){
     data = new Array<>(arr);
     for(int i = parent(arr.length - 1); i >= 0; i --){
         siftDown(i);
     }
1}
```