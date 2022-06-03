---
layout: post
title: Java 文件 IO 使用方法
date: 2021-03-30 22:49 +0800
categories: [Software Development] 
tags: [Java, IO]
---


# 创建并写文件的五种方式
java中创建文件的五种方法
1. Files.newBufferedWriter
2. Files.write(Java 7 推荐)
3. PrintWriter
4. File.createNewFile
5. FileOutputStream.write(byte[] b) 管道流

```java
try(管道, 流连接等实现了Closeable接口的类){
    //这里使用类对象操作
}
```
>用try()包含起来，就不用在finally里面自己手动的去 Object.close()了，会自动的关闭
{: .prompt-tip }

## Java 8 Files.newBufferedWriter
java8 提供的newBufferedWriter可以创建文件，并向文件内写入数据。可以通过追加写模式，向文件内追加内容。
```java
@Test
void testCreateFile1() throws IOException {
   String fileName = "D:\data\test\newFile.txt";

   Path path = Paths.get(fileName);
   // 使用newBufferedWriter创建文件并写文件
   // 这里使用了try-with-resources方法来关闭流，不用手动关闭
   try (BufferedWriter writer =
                   Files.newBufferedWriter(path, StandardCharsets.UTF_8)) {
      writer.write("Hello World -创建文件!!");
   }

   //追加写模式
   try (BufferedWriter writer =
                Files.newBufferedWriter(path,
                        StandardCharsets.UTF_8,
                        StandardOpenOption.APPEND)){
       writer.write("Hello World -字母哥!!");
   }
}
```

## Java 7 Files.write
下面的这种方式Files.write，是推荐的方式，语法简单，而且底层是使用Java NIO实现的。同样提供追加写模式向已经存在的文件种追加数据。这种方式是实现文本文件简单读写最方便快捷的方式。
```java
@Test
void testCreateFile2() throws IOException {
   String fileName = "D:\data\test\newFile2.txt";

   // 从JDK1.7开始提供的方法
   // 使用Files.write创建一个文件并写入
   Files.write(Paths.get(fileName),
               "Hello World -创建文件!!".getBytes(StandardCharsets.UTF_8));

   // 追加写模式
   Files.write(
         Paths.get(fileName),
         "Hello World -字母哥!!".getBytes(StandardCharsets.UTF_8),
         StandardOpenOption.APPEND);
}
```

## PrintWriter
PrintWriter是一个比较古老的文件创建及写入方式，从JDK1.5就已经存在了，比较有特点的是：PrintWriter的println方法，可以实现一行一行的写文件。
```java
@Test
void testCreateFile3() throws IOException {
   String fileName = "D:\data\test\newFile3.txt";

   // JSD 1.5开始就已经存在的方法
   try (PrintWriter writer = new PrintWriter(fileName, "UTF-8")) {
      writer.println("Hello World -创建文件!!");
      writer.println("Hello World -字母哥!!");
   }

   // Java 10进行了改进，支持使用StandardCharsets指定字符集
   /*try (PrintWriter writer = new PrintWriter(fileName, StandardCharsets.UTF_8)) {

      writer.println("first line!");
      writer.println("second line!");
   } */
}
```

## File.createNewFile()
createNewFile()方法的功能相对就比较纯粹，只是创建文件不做文件写入操作。 返回true表示文件成功，返回 false表示文件已经存在.可以配合FileWriter 来完成文件的写操作
```java
@Test
void testCreateFile4() throws IOException {
   String fileName = "D:\data\test\newFile4.txt";

   File file = new File(fileName);

   // 返回true表示文件成功
   // false 表示文件已经存在
   if (file.createNewFile()) {
      System.out.println("创建文件成功！");
   } else {
      System.out.println("文件已经存在不需要重复创建");
   }

   // 使用FileWriter写文件
   try (FileWriter writer = new FileWriter(file)) {
      writer.write("Hello World -创建文件!!");
   }
}
```

## 最原始的管道流方法
最原始的方式就是使用管道流嵌套的方法，使用起来非常灵活。你想去加上Buffer缓冲，你就嵌套一个BufferedWriter，你想去向文件中写java对象你就嵌套一个ObjectOutputStream。但归根结底要用到FileOutputStream
```java
@Test
void testCreateFile5() throws IOException {
   String fileName = "D:\data\test\newFile5.txt";
   try(FileOutputStream fos = new FileOutputStream(fileName);
      OutputStreamWriter osw = new OutputStreamWriter(fos);
      BufferedWriter bw = new BufferedWriter(osw);){
      bw.write("Hello World -创建文件!!");
      bw.flush();
   }
}
```


# 从文件中读取数据的6种方法
6种从文件中读取数据的方法：
1. Scanner(Java 1.5)  按行读数据及String、Int类型等按分隔符读数据。
2. Files.lines, 返回Stream(Java 流式数据处理，按行读取)
3. Files.readAllLines, 返回List\<String\>
4. Files.readString, 读取String(Java 11), 文件最大 2G.
5. Files.readAllBytes, 读取byte[](Java 7), 文件最大 2G.
6. BufferedReader, 经典方式 (Java 1.1 -> forever)

## Scanner
第一种方式是Scanner，从JDK1.5开始提供的API，特点是可以按行读取、按分割符去读取文件数据，既可以读取String类型，也可以读取Int类型、Long类型等基础数据类型的数据。
```java
@Test
void testReadFile1() throws IOException {
   //文件内容：Hello World|Hello Zimug
   String fileName = "D:\data\test\newFile4.txt";

   try (Scanner sc = new Scanner(new FileReader(fileName))) {
      while (sc.hasNextLine()) {  //按行读取字符串
         String line = sc.nextLine();
         System.out.println(line);
      }
   }

   try (Scanner sc = new Scanner(new FileReader(fileName))) {
      sc.useDelimiter("\|");  //分隔符
      while (sc.hasNext()) {   //按分隔符读取字符串
         String str = sc.next();
         System.out.println(str);
      }
   }

   //sc.hasNextInt() 、hasNextFloat() 、基础数据类型等等等等。
   //文件内容：1|2
   fileName = "D:\data\test\newFile5.txt";
   try (Scanner sc = new Scanner(new FileReader(fileName))) {
      sc.useDelimiter("\|");  //分隔符
      while (sc.hasNextInt()) {   //按分隔符读取Int
          int intValue = sc.nextInt();
         System.out.println(intValue);
      }
   }
}
```
上面的方法输出结果如下：
```
Hello World|Hello Zimug
Hello World
Hello Zimug
1
2
```

## Files.lines (Java 8)
如果是需要按行去处理数据文件的内容，这种方式是推荐使用的一种方式，代码简洁，使用java 8的Stream流将文件读取与文件处理有机融合。
```java
@Test
void testReadFile2() throws IOException {
   String fileName = "D:\data\test\newFile.txt";

   // 读取文件内容到Stream流中，按行读取
   Stream<String> lines = Files.lines(Paths.get(fileName));

   // 随机行顺序进行数据处理
   lines.forEach(ele -> {
      System.out.println(ele);
   });
}
```
forEach获取Stream流中的行数据不能保证顺序，但速度快。如果你想按顺序去处理文件中的行数据，可以使用forEachOrdered，但处理效率会下降。
```java
// 按文件行顺序进行处理
lines.forEachOrdered(System.out::println);
```
或者利用CPU多和的能力，进行数据的并行处理parallel()，适合比较大的文件。
```java
// 按文件行顺序进行处理
lines.parallel().forEachOrdered(System.out::println);
```
也可以把Stream\<String\>转换成List\<String\>,但是要注意这意味着你要将所有的数据一次性加载到内存，要注意java.lang.OutOfMemoryError
```java
// 转换成List<String>, 要注意java.lang.OutOfMemoryError: Java heap space
List<String> collect = lines.collect(Collectors.toList());
```

## Files.readAllLines
这种方法仍然是java8 为我们提供的，如果我们不需要Stream<String>,我们想直接按行读取文件获取到一个List<String>，就采用下面的方法。同样的问题：这意味着你要将所有的数据一次性加载到内存，要注意java.lang.OutOfMemoryError
```java
@Test
void testReadFile3() throws IOException {
   String fileName = "D:\data\test\newFile3.txt";

   // 转换成List<String>, 要注意java.lang.OutOfMemoryError: Java heap space
   List<String> lines = Files.readAllLines(Paths.get(fileName),
               StandardCharsets.UTF_8);
   lines.forEach(System.out::println);
}
```

## Files.readString(JDK 11)
从 java11开始，为我们提供了一次性读取一个文件的方法。文件不能超过2G，同时要注意你的服务器及JVM内存。这种方法适合快速读取小文本文件。
```java
@Test
void testReadFile4() throws IOException {
   String fileName = "D:\data\test\newFile3.txt";

   // java 11 开始提供的方法，读取文件不能超过2G，与你的内存息息相关
   //String s = Files.readString(Paths.get(fileName));
}
```

## Files.readAllBytes
如果你没有JDK11（readAllBytes()始于JDK7）,仍然想一次性的快速读取一个文件的内容转为String，该怎么办？先将数据读取为二进制数组，然后转换成String内容。这种方法适合在没有JDK11的请开给你下，快速读取小文本文件
```java
@Test
void testReadFile5() throws IOException {
   String fileName = "D:\data\test\newFile3.txt";

   //如果是JDK11用上面的方法，如果不是用这个方法也很容易
   byte[] bytes = Files.readAllBytes(Paths.get(fileName));

   String content = new String(bytes, StandardCharsets.UTF_8);
   System.out.println(content);
}
```

## 经典管道流的方式
最后一种就是经典的管道流的方式
```java
@Test
void testReadFile6() throws IOException {
   String fileName = "D:\data\test\newFile3.txt";

   // 带缓冲的流读取，默认缓冲区8k
   try (BufferedReader br = new BufferedReader(new FileReader(fileName))){
      String line;
      while ((line = br.readLine()) != null) {
         System.out.println(line);
      }
   }

   //java 8中这样写也可以
   try (BufferedReader br = Files.newBufferedReader(Paths.get(fileName))){
      String line;
      while ((line = br.readLine()) != null) {
         System.out.println(line);
      }
   }

} 
```
这种方式可以通过管道流嵌套的方式，组合使用，比较灵活。比如我们
 想从文件中读取java Object就可以使用下面的代码，前提是文件中的数据是ObjectOutputStream写入的数据，才可以用ObjectInputStream来读取。
```java
try (FileInputStream fis = new FileInputStream(fileName);
     ObjectInputStream ois = new ObjectInputStream(fis)){
   ois.readObject();
} 
```


# 创建文件夹的4种方法及其优缺点
## 传统API创建文件夹方式
Java传统的IO API种使用java.io.File类中的file.mkdir()和file.mkdirs()方法创建文件夹

- file.mkdir()创建文件夹成功返回true，失败返回false。如果被创建文件夹的父文件夹不存在也返回false.没有异常抛出。
- file.mkdirs()创建文件夹连同该文件夹的父文件夹，如果创建成功返回true，创建失败返回false。创建失败同样没有异常抛出。

```java
@Test
void testCreateDir1() {
   //“D:\data111”目录现在不存在
   String dirStr = "D:\data111\test";
   File directory = new File(dirStr);

   //mkdir
   boolean hasSucceeded = directory.mkdir();
   System.out.println("创建文件夹结果（不含父文件夹）：" + hasSucceeded);

   //mkdirs
   hasSucceeded = directory.mkdirs();
   System.out.println("创建文件夹结果（包含父文件夹）：" + hasSucceeded);
}
```
输出结果如下：使用mkdir创建失败，使用mkdirs创建成功。
```
创建文件夹结果（不含父文件夹）：false
创建文件夹结果（包含父文件夹）：true
```
大家可以看到，mkdir和mkdirs虽然可以创建文件，但是它们在异常处理的环节做的非常不友好。创建失败之后统一返回false，创建失败的原因没有说明。是父文件夹不存在所以创建失败？还是文件夹已经存在所以创建失败？还是因为磁盘IO原因导致创建文件夹失败？

## Java NIO创建文件夹
为了解决传统IO创建文件夹中异常失败处理问题不明确的问题，在Java的NIO中进行了改进。
### Files.createDirectory创建文件夹
Files.createDirectory创建文件夹
- 如果被创建文件夹的父文件夹不存在，则抛出NoSuchFileException.
- 如果被创建的文件夹已经存在，则抛出FileAlreadyExistsException.
- 如果因为磁盘IO出现异常，则抛出IOException.

```java
Path path = Paths.get("D:\data222\test");
Path pathCreate = Files.createDirectory(path);
```

### Files.createDirectories创建文件夹及其父文件夹
Files.createDirectories创建文件夹及其父文件夹
- 如果被创建文件夹的父文件夹不存在，就创建它
- 如果被创建的文件夹已经存在，就是用已经存在的文件夹，不会重复创建，没有异常抛出
- 如果因为磁盘IO出现异常，则抛出IOException.

```java
Path path = Paths.get("D:\data222\test");
Path pathCreate = Files.createDirectorys(path);
```
>另外要注意：NIO的API创建的文件夹返回值是Path，这样方便我们在创建完成文件夹之后继续向文件夹里面写入文件数据等操作。比传统IO只返回一个boolean值要好得多。
{: .prompt-tip }


# 删除文件或文件夹的7种方法
## 删除文件或文件夹的四种基础方法
下面的四个方法都可以删除文件或文件夹，它们的共同点是：当文件夹中包含子文件的时候都会删除失败，也就是说这四个方法只能删除空文件夹。

>需要注意的是：传统IO中的File类和NIO中的Path类既可以代表文件，也可以代表文件夹。
{: .prompt-warning }

- File类的delete()
- File类的deleteOnExit()
- Files.delete(Path path)
- Files.deleteIfExists(Path path);

它们之间的差异：

| 成功的返回值                    | 是否能判别文件夹不存在导致失败 | 是否能判别文件夹不为空导致失败 | 备注                       |                            |
| :------------------------------ | :----------------------------- | :----------------------------- | :------------------------- | :------------------------- |
| File类的delete()                | true                           | 不能(返回false)                | 不能(返回false)            | 传统IO                     |
| File类的deleteOnExit()          | void                           | 不能，但不存在就不会去执行删除 | 不能(返回void)             | 传统IO，这是个坑，避免使用 |
| Files.delete(Path path)         | void                           | NoSuchFileException            | DirectoryNotEmptyException | NIO，笔者推荐使用          |
| Files.deleteIfExists(Path path) | true                           | false                          | DirectoryNotEmptyException | NIO                        |

- 由上面的对比可以看出，传统IO方法删除文件或文件夹，再删除失败的时候，最多返回一个false。通过这个false无法发掘删除失败的具体原因，是因为文件本身不存在删除失败？还是文件夹不为空导致的删除失败？
- NIO 的方法在这一点上，就做的比较好，删除成功或失败都有具体的返回值或者异常信息，这样有利于我们在删除文件或文件夹的时候更好的做程序的异常处理
- 需要注意的是传统IO中的deleteOnExit方法，笔者觉得应该避免使用它。它永远只返回void，删除失败也不会有任何的Exception抛出，所以我建议不要用，以免在你删除失败的时候没有任何的响应，而你可能误以为删除成功了

```java
//false只能告诉你失败了 ，但是没有给出任何失败的原因
@Test
void testDeleteFileDir1()  {
   File file = new File("D:\data\test");
   boolean deleted = file.delete();
   System.out.println(deleted);
}

//void ,删除失败没有任何提示，应避免使用这个方法，就是个坑
@Test
void testDeleteFileDir2()  {
   File file = new File("D:\data\test1");
   file.deleteOnExit();
}

//如果文件不存在，抛出NoSuchFileException
//如果文件夹里面包含文件，抛出DirectoryNotEmptyException
@Test
void testDeleteFileDir3() throws IOException {
   Path path = Paths.get("D:\data\test1");
   Files.delete(path);   //返回值void
}

//如果文件不存在，返回false，表示删除失败(文件不存在)
//如果文件夹里面包含文件，抛出DirectoryNotEmptyException
@Test
void testDeleteFileDir4() throws IOException {
   Path path = Paths.get("D:\data\test1");
   boolean result = Files.deleteIfExists(path);
   System.out.println(result);
}
```
归根结底，建议使用java NIO的Files.delete(Path path)和Files.deleteIfExists(Path path);进行文件或文件夹的删除。

## 如何删除整个目录或者目录中的部分文件
上文已经说了，那四个API删除文件夹的时候，如果文件夹包含子文件，就会删除失败。那么，如果我们确实想删除整个文件夹，该怎么办？

**前提准备**
为了方便我们后面进行测试，先去创建这样一个目录结构，“.log”结尾的是数据文件，其他的是文件夹
```
data 
  |--test1
    |--test2
      |== test2.log
      |-- test3
        |== test3. log
        |-- test4
          |-- test5   
```
可以使用下面的代码进行创建
```java
private  void createMoreFiles() throws IOException {
   Files.createDirectories(Paths.get("D:\data\test1\test2\test3\test4\test5\"));
   Files.write(Paths.get("D:\data\test1\test2\test2.log"), "hello".getBytes());
   Files.write(Paths.get("D:\data\test1\test2\test3\test3.log"), "hello".getBytes());
}
```
### walkFileTree与FileVisitor
- 使用walkFileTree方法遍历整个文件目录树，使用FileVisitor处理遍历出来的每一项文件或文件夹
- FileVisitor的visitFile方法用来处理遍历结果中的“文件”，所以我们可以在这个方法里面删除文件
- FileVisitor的postVisitDirectory方法，注意方法中的“post”表示“后去做……”的意思，所以用来文件都处理完成之后再去处理文件夹，所以使用这个方法删除文件夹就可以有效避免文件夹内容不为空的异常，因为在去删除文件夹之前，该文件夹里面的文件已经被删除了。

```java
@Test
void testDeleteFileDir5() throws IOException {
   createMoreFiles();
   Path path = Paths.get("D:\data\test1\test2");

   Files.walkFileTree(path,
      new SimpleFileVisitor<Path>() {
         // 先去遍历删除文件
         @Override
         public FileVisitResult visitFile(Path file,
                                  BasicFileAttributes attrs) throws IOException {
            Files.delete(file);
            System.out.printf("文件被删除 : %s%n", file);
            return FileVisitResult.CONTINUE;
         }
         // 再去遍历删除目录
         @Override
         public FileVisitResult postVisitDirectory(Path dir,
                                         IOException exc) throws IOException {
            Files.delete(dir);
            System.out.printf("文件夹被删除: %s%n", dir);
            return FileVisitResult.CONTINUE;
         }
      }
   );
}
```
下面的输出体现了文件的删除顺序
```
文件被删除 : D:\data\test1\test2\test2.log
文件被删除 : D:\data\test1\test2\test3\test3.log
文件夹被删除 : D:\data\test1\test2\test3\test4\test5
文件夹被删除 : D:\data\test1\test2\test3\test4
文件夹被删除 : D:\data\test1\test2\test3
文件夹被删除 : D:\data\test1\test2
```
我们既然可以遍历出文件夹或者文件，我们就可以在处理的过程中进行过滤。比如：

- 按文件名删除文件或文件夹，参数Path里面含有文件或文件夹名称
- 按文件创建时间、修改时间、文件大小等信息去删除文件，参数BasicFileAttributes 里面包含了这些文件信息。

### Files.walk
如果你对Stream流语法不太熟悉的话，这种方法稍微难理解一点，但是说实话也非常简单。

- 使用Files.walk遍历文件夹（包含子文件夹及子其文件），遍历结果是一个Stream\<Path\>
- 对每一个遍历出来的结果进行处理，调用Files.delete就可以了。

```java
@Test
void testDeleteFileDir6() throws IOException {
   createMoreFiles();
   Path path = Paths.get("D:\data\test1\test2");

   try (Stream<Path> walk = Files.walk(path)) {
      walk.sorted(Comparator.reverseOrder())
         .forEach(DeleteFileDir::deleteDirectoryStream);
   }
}

private static void deleteDirectoryStream(Path path) {
   try {
      Files.delete(path);
      System.out.printf("删除文件成功：%s%n",path.toString());
   } catch (IOException e) {
      System.err.printf("无法删除的路径 %s%n%s", path, e);
   }
}
```
问题：怎么能做到先去删除文件，再去删除文件夹？ 。 利用的是字符串的排序规则，从字符串排序规则上讲，“D:\data\test1\test2”一定排在“D:\data\test1\test2\test2.log”的前面。所以我们使用“sorted(Comparator.reverseOrder())”把Stream顺序颠倒一下，就达到了先删除文件，再删除文件夹的目的。
下面的输出，是最终执行结果的删除顺序。
```
删除文件成功：D:\data\test1\test2\test3\test4\test5
删除文件成功：D:\data\test1\test2\test3\test4
删除文件成功：D:\data\test1\test2\test3\test3.log
删除文件成功：D:\data\test1\test2\test3
删除文件成功：D:\data\test1\test2\test2.log
删除文件成功：D:\data\test1\test2
```

### 传统IO-递归遍历删除文件夹
传统的通过递归去删除文件或文件夹的方法就比较经典了
```java
//传统IO递归删除
@Test
void testDeleteFileDir7() throws IOException {
   createMoreFiles();
   File file = new File("D:\data\test1\test2");
   deleteDirectoryLegacyIO(file);
}

private void deleteDirectoryLegacyIO(File file) {

   File[] list = file.listFiles();  //无法做到list多层文件夹数据
   if (list != null) {
      for (File temp : list) {     //先去递归删除子文件夹及子文件
         deleteDirectoryLegacyIO(temp);   //注意这里是递归调用
      }
   }

   if (file.delete()) {     //再删除自己本身的文件夹
      System.out.printf("删除成功 : %s%n", file);
   } else {
      System.err.printf("删除失败 : %s%n", file);
   }
}
```
>listFiles()方法只能列出文件夹下面的一层文件或文件夹，不能列出子文件夹及其子文件。
>
>先去递归删除子文件夹，再去删除文件夹自己本身
{: .prompt-warning }


# 文件拷贝剪切的5种方式
- 文件拷贝：将文件从一个文件夹复制到另一个文件夹
- 文件剪切：将文件从当前文件夹，移动到另一个文件夹
- 文件重命名：将文件在当前文件夹下面改名（也可以理解为将文件剪切为当前文件夹下面的另一个文件）

## 文件拷贝
传统IO中的文件copy的方法，使用输入输出流，实际上就是重新创建并写入一个文件。如果目标文件已经存在，就覆盖掉它，重新创建一个文件并写入数据。这种方式不够友好，覆盖掉原有文件没有给出任何提示，有可能导致原有数据的丢失。
```java
@Test
void testCopyFile1() throws IOException {
  File fromFile = new File("D:\data\test\newFile.txt");
  File toFile = new File("D:\data\test2\copyedFile.txt");

  try(InputStream inStream = new FileInputStream(fromFile);
      OutputStream outStream = new FileOutputStream(toFile);) {

    byte[] buffer = new byte[1024];

    int length;
    while ((length = inStream.read(buffer)) > 0) {
      outStream.write(buffer, 0, length);
      outStream.flush();
    }

  }
}
```
Java NIO中文件copy的方法，使用方式简单。当目标文件已经存在的时候会抛出FileAlreadyExistsException ，当源文件不存在的时候抛出NoSuchFileException，针对不同的异常场景给出不同的Exception，更有利于我们写出健壮性更好的程序。
```java
@Test
void testCopyFile2() throws IOException {
  Path fromFile = Paths.get("D:\data\test\newFile.txt");
  Path toFile = Paths.get("D:\data\test2\copyedFile.txt");

  Files.copy(fromFile, toFile);
}
```
如果在目标文件已经存在的情况下，你不想抛出FileAlreadyExistsException ，而是去覆盖它，也可以灵活的选择使用下面的选项

StandardCopyOption.REPLACE_EXISTING 来忽略文件已经存在的异常，如果存在就去覆盖掉它
```java
//如果目标文件存在就替换它
Files.copy(fromFile, toFile, StandardCopyOption.REPLACE_EXISTING);
```
StandardCopyOption.COPY_ATTRIBUTES copy文件的属性，最近修改时间，最近访问时间等信息，不仅copy文件的内容，连文件附带的属性一并复制
```java
CopyOption[] options = { StandardCopyOption.REPLACE_EXISTING,
      StandardCopyOption.COPY_ATTRIBUTES //copy文件的属性，最近修改时间，最近访问时间等
};
Files.copy(fromFile, toFile, options);
```

## 文件重命名
NIO中可以使用Files.move方法在同一个文件夹内移动文件，并更换名字。当目标文件已经存在的时候，同样会有FileAlreadyExistsException，也同样可以使用StandardCopyOption去处理该异常。
```java
@Test
void testRenameFile() throws IOException {
  Path source = Paths.get("D:\data\test\newFile.txt");
  Path target = Paths.get("D:\data\test\renameFile.txt");

  //REPLACE_EXISTING文件存在就替换它
  Files.move(source, target,StandardCopyOption.REPLACE_EXISTING);
}
```
下文中的实现方法和上面代码的效果是一样的，resolveSibling作用是将source文件的父路径与参数文件名合并为一个新的文件路径。

> resolve系列函数在windows和linux等各种系统处理路径分隔符号、路径与文件名合并等，比自己手写代码去处理不同操作系统的路径分隔符号、路径与文件名合并有更好的操作系统兼容性
{: .prompt-tip  }

```java
@Test
void testRenameFile2() throws IOException {
  Path source = Paths.get("D:\data\test\newFile.txt");

  //这种写法就更加简单，兼容性更好
  Files.move(source, source.resolveSibling("renameFile.txt"));
}
```
传统IO中使用File类的renameTo方法重命名，失败了就返回false，没有任何异常抛出。你不会知道你失败的原因是什么，是因为源文件不存在导致失败？还是因为目标文件已经存在导致失败？所以这种方法不建议使用。
```java
@Test
void testRenameFile3() throws IOException {

  File source = new File("D:\data\test\newFile.txt");
  boolean succeeded = source.renameTo(new File("D:\data\test\renameFile.txt"));
  System.out.println(succeeded);  //失败了false，没有异常
}
```

## 文件剪切
文件剪切实际上仍然是Files.move，如果move的目标文件夹不存在或源文件不存在，都会抛出NoSuchFileException
```java
@Test
void testMoveFile() throws IOException {

  Path fromFile = Paths.get("D:\data\test\newFile.txt"); //文件
  Path anotherDir = Paths.get("D:\data\test\anotherDir"); //目标文件夹

  Files.createDirectories(anotherDir);
  Files.move(fromFile, anotherDir.resolve(fromFile.getFileName()),
          StandardCopyOption.REPLACE_EXISTING);
}
```
resolve函数是解析anotherDir路径与参数文件名进行合并为一个新的文件路径。


