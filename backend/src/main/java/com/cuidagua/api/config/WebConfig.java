package com.cuidagua.api.config;

import com.cuidagua.api.common.catalogo.ValorCatalogo;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.core.convert.converter.ConverterFactory;
import org.springframework.format.FormatterRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Permite usar los valores del catálogo en parámetros de URL
 * (ej. {@code ?estado=en_revision&categoria=fuga}) en lugar del nombre del enum.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addFormatters(FormatterRegistry registry) {
        registry.addConverterFactory(new StringACatalogo());
    }

    private static final class StringACatalogo implements ConverterFactory<String, ValorCatalogo> {

        @Override
        @SuppressWarnings({"unchecked", "rawtypes"})
        public <T extends ValorCatalogo> Converter<String, T> getConverter(Class<T> tipo) {
            return valor -> valor.isBlank() ? null : (T) ValorCatalogo.desde((Class) tipo, valor);
        }
    }
}
