---
layout: post
title: 使用 Java 压缩和解压文件与文件夹
date: 2021-03-25 22:42 +0800
categories: [Software Development] 
tags: [Java, IO, DevDairy]
---

# 压缩文件
将一个名为test1.txt的文件压缩到一个名为Compressed.zip的zip文件中。
```java
public class ZipFile {
    public static void main(String[] args) throws IOException {
       
        //输出压缩包
        FileOutputStream fos = new FileOutputStream("src/main/resources/compressed.zip");
        ZipOutputStream zipOut = new ZipOutputStream(fos);

        //被压缩文件
        File fileToZip = new File("src/main/resources/test1.txt");
        FileInputStream fis = new FileInputStream(fileToZip);
        
        //向压缩包中添加文件
        ZipEntry zipEntry = new ZipEntry(fileToZip.getName());
        zipOut.putNextEntry(zipEntry);
        byte[] bytes = new byte[1024];
        int length;
        while((length = fis.read(bytes)) >= 0) {
            zipOut.write(bytes, 0, length);
        }
        zipOut.close();
        fis.close();
        fos.close();
    }
}
```

# 压缩多个文件
将把test1.txt和test2.txt压缩成multiCompressed.zip
```java
public class ZipMultipleFiles {
    public static void main(String[] args) throws IOException {
        List<String> srcFiles = Arrays.asList("src/main/resources/test1.txt", "src/main/resources/test2.txt");
        FileOutputStream fos = new FileOutputStream("src/main/resources/multiCompressed.zip");
        ZipOutputStream zipOut = new ZipOutputStream(fos);
        //向压缩包中添加多个文件
        for (String srcFile : srcFiles) {
            File fileToZip = new File(srcFile);
            FileInputStream fis = new FileInputStream(fileToZip);
            ZipEntry zipEntry = new ZipEntry(fileToZip.getName());
            zipOut.putNextEntry(zipEntry);
 
            byte[] bytes = new byte[1024];
            int length;
            while((length = fis.read(bytes)) >= 0) {
                zipOut.write(bytes, 0, length);
            }
            fis.close();
        }
        zipOut.close();
        fos.close();
    }
}
```

# 压缩目录
将zipTest目录及该目录下的递归子目录文件，全都压缩到dirCompressed.zip中
```java
public class ZipDirectory {
    public static void main(String[] args) throws IOException, FileNotFoundException {
        //被压缩的文件夹
        String sourceFile = "src/main/resources/zipTest"; 
        //压缩结果输出，即压缩包
        FileOutputStream fos = new FileOutputStream("src/main/resources/dirCompressed.zip");
        ZipOutputStream zipOut = new ZipOutputStream(fos);
        File fileToZip = new File(sourceFile);
        //递归压缩文件夹
        zipFile(fileToZip, fileToZip.getName(), zipOut);
        //关闭输出流
        zipOut.close();
        fos.close();
    }
     

    /**
     * 将fileToZip文件夹及其子目录文件递归压缩到zip文件中
     * @param fileToZip 递归当前处理对象，可能是文件夹，也可能是文件
     * @param fileName fileToZip文件或文件夹名称
     * @param zipOut 压缩文件输出流
     * @throws IOException
     */
    private static void zipFile(File fileToZip, String fileName, ZipOutputStream zipOut) throws IOException {
        //不压缩隐藏文件夹
        if (fileToZip.isHidden()) {
            return;
        }
        //判断压缩对象如果是一个文件夹
        if (fileToZip.isDirectory()) {
            if (fileName.endsWith("/")) {
                //如果文件夹是以“/”结尾，将文件夹作为压缩箱放入zipOut压缩输出流
                zipOut.putNextEntry(new ZipEntry(fileName));
                zipOut.closeEntry();
            } else {
                //如果文件夹不是以“/”结尾，将文件夹结尾加上“/”之后作为压缩箱放入zipOut压缩输出流
                zipOut.putNextEntry(new ZipEntry(fileName + "/"));
                zipOut.closeEntry();
            }
            //遍历文件夹子目录，进行递归的zipFile
            File[] children = fileToZip.listFiles();
            for (File childFile : children) {
                zipFile(childFile, fileName + "/" + childFile.getName(), zipOut);
            }
            //如果当前递归对象是文件夹，加入ZipEntry之后就返回
            return;
        }
        //如果当前的fileToZip不是一个文件夹，是一个文件，将其以字节码形式压缩到压缩包里面
        FileInputStream fis = new FileInputStream(fileToZip);
        ZipEntry zipEntry = new ZipEntry(fileName);
        zipOut.putNextEntry(zipEntry);
        byte[] bytes = new byte[1024];
        int length;
        while ((length = fis.read(bytes)) >= 0) {
            zipOut.write(bytes, 0, length);
        }
        fis.close();
    }
}
```
- 要压缩子目录及其子目录文件，所以需要递归遍历
- 每次遍历找到的是目录时，我们都将其名称附加“/”,并将其以ZipEntry保存到压缩包中，从而保持压缩的目录结构。
- 每次遍历找到的是文件时，将其以字节码形式压缩到压缩包里面

# 解压缩zip压缩包
我们将compressed.zip解压缩到名为unzipTest的新文件夹中
```java
public class UnzipFile {
    public static void main(String[] args) throws IOException {
        //被解压的压缩文件
        String fileZip = "src/main/resources/unzipTest/compressed.zip";
        //解压的目标目录
        File destDir = new File("src/main/resources/unzipTest");

        byte[] buffer = new byte[1024];
        ZipInputStream zis = new ZipInputStream(new FileInputStream(fileZip));
        //获取压缩包中的entry，并将其解压
        ZipEntry zipEntry = zis.getNextEntry();
        while (zipEntry != null) {
            File newFile = newFile(destDir, zipEntry);
            FileOutputStream fos = new FileOutputStream(newFile);
            int len;
            while ((len = zis.read(buffer)) > 0) {
                fos.write(buffer, 0, len);
            }
            fos.close();
            //解压完成一个entry，再解压下一个
            zipEntry = zis.getNextEntry();
        }
        zis.closeEntry();
        zis.close();
    }
    //在解压目标文件夹，新建一个文件
    public static File newFile(File destinationDir, ZipEntry zipEntry) throws IOException {
        File destFile = new File(destinationDir, zipEntry.getName());

        String destDirPath = destinationDir.getCanonicalPath();
        String destFilePath = destFile.getCanonicalPath();

        if (!destFilePath.startsWith(destDirPath + File.separator)) {
            throw new IOException("该解压项在目标文件夹之外: " + zipEntry.getName());
        }

        return destFile;
    }
}
```
