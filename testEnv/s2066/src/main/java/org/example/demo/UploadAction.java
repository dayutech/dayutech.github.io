package org.example.demo;


import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.dispatcher.multipart.UploadedFile;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;

public class UploadAction extends ActionSupport {
    private UploadedFile upload;
    private String uploadFileName;
    private String uploadContentType;

    public UploadedFile getUpload() {
        return upload;
    }

    public void setUpload(UploadedFile upload) {
        this.upload = upload;
    }

    public String getUploadFileName() {
        return uploadFileName;
    }

    public void setUploadFileName(String uploadFileName) {
        this.uploadFileName = uploadFileName;
    }

    public String getUploadContentType() {
        return uploadContentType;
    }

    public void setUploadContentType(String uploadContentType) {
        this.uploadContentType = uploadContentType;
    }

    @Override
    public String execute() throws Exception {
        System.out.println("uploadFileName:" + uploadFileName);
        File file = new File(uploadFileName);
        FileOutputStream fileOutputStream = new FileOutputStream(file);
        File content = (File) upload.getContent();
        FileInputStream fileInputStream = new FileInputStream(content);
        byte[] fileContent = Files.readAllBytes(content.toPath());
        fileOutputStream.write(fileContent);
        fileOutputStream.flush();
        fileOutputStream.close();

        return super.execute();
    }
}
