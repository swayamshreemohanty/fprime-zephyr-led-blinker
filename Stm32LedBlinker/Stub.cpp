// Stubs needed to prevent linking errors between the fprime and zephyr build system

#include <zephyr/kernel.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

// Zephyr assert stubs
extern "C" {
    void assert_print(const char *fmt, ...) {
        // Simplified assert output
        printk("ASSERT: %s\n", fmt ? fmt : "");
    }
    
    void assert_post_action(const char *file, unsigned int line) {
        printk("Assert at %s:%u\n", file ? file : "unknown", line);
        k_panic();
    }
    
    void __assert_func(const char *file, int line, const char *func, const char *failedexpr) {
        printk("ASSERT FAILED: %s:%d %s() - %s\n", file, line, func, failedexpr);
        k_panic();
    }
    
    // C library stubs for Zephyr minimal newlib
    int fputs(const char *s, FILE *stream) {
        printk("%s", s);
        return 0;
    }
    
    int fputc(int c, FILE *stream) {
        char ch = (char)c;
        printk("%c", ch);
        return c;
    }
    
    struct _reent *_impure_ptr = NULL;
    
    char* strncpy(char *dest, const char *src, size_t n) {
        size_t i;
        for (i = 0; i < n && src[i] != '\0'; i++)
            dest[i] = src[i];
        for ( ; i < n; i++)
            dest[i] = '\0';
        return dest;
    }
    
    char* strncat(char *dest, const char *src, size_t n) {
        size_t dest_len = strlen(dest);
        size_t i;
        for (i = 0 ; i < n && src[i] != '\0' ; i++)
            dest[dest_len + i] = src[i];
        dest[dest_len + i] = '\0';
        return dest;
    }
    
    int vsnprintk(char *str, size_t size, const char *format, va_list ap) {
        return vsnprintf(str, size, format, ap);
    }
    
    // C++ runtime stubs
    void *__dso_handle = nullptr;
    
    int __aeabi_atexit(void *object, void (*destructor)(void *), void *dso_handle) {
        return 0;
    }
}
