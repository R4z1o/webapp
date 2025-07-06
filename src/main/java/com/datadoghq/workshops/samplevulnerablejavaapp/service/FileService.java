package com.datadoghq.workshops.samplevulnerablejavaapp.service;

import com.datadoghq.workshops.samplevulnerablejavaapp.exception.FileForbiddenFileException;
import com.datadoghq.workshops.samplevulnerablejavaapp.exception.FileReadException;
import org.springframework.stereotype.Service;

import java.io.*;

@Service
public class FileService {
    final static String ALLOWED_PREFIX = "/tmp/files/";

    public String readFile(String path) throws FileForbiddenFileException, FileReadException {

        try (BufferedReader br = new BufferedReader(new FileReader(ALLOWED_PREFIX + path))) {
            StringBuilder sb = new StringBuilder();
            String line = br.readLine();

            while (line != null) {
                sb.append(line);
                sb.append(System.lineSeparator());
                line = br.readLine();
            }
            return sb.toString();
        } catch (IOException e) {
            throw new FileReadException(e.getMessage());
        }
    }
}
