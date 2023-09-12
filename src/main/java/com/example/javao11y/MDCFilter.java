package com.example.javao11y;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;

import java.io.IOException;

public class MDCFilter implements Filter {
    private static final String CORRELATION_ID_KEY = "correlation_id";

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) servletRequest;
        String headerValue = httpRequest.getHeader("Correlation-ID");

        try {
            MDC.put(CORRELATION_ID_KEY, headerValue);
            filterChain.doFilter(servletRequest, servletResponse);
        } finally {
            MDC.remove(CORRELATION_ID_KEY);
        }
    }

    @Override
    public void destroy() {
    }
}
