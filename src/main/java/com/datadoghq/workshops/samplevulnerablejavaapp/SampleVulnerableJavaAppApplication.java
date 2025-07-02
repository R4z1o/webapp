package com.datadoghq.workshops.samplevulnerablejavaapp;

import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SampleVulnerableJavaAppApplication extends SpringBootServletInitializer {
    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(SampleVulnerableJavaAppApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(SampleVulnerableJavaAppApplication.class, args);
    }
}

