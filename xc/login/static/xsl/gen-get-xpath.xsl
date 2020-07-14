<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:alt="http://example.com/XSL/"
  version="1.0">

  <xsl:output method="xml"/>

  <xsl:namespace-alias result-prefix="xsl" stylesheet-prefix="alt"/>

  <xsl:template match="/">
    <alt:stylesheet version="1.0">
      <alt:output method="{/*/output}" indent="yes"/>
      <alt:template match="/">
        <xsl:choose>
          <xsl:when test="/*/output = 'xml' and string-length(/*/wrap)>0">
            <alt:element name="{/*/wrap}" namespace="http://ai-and-it.de/xmlns/2020/xc">
              <alt:copy-of select="{/*/xpath-expr}"/>
            </alt:element>
          </xsl:when>
          <xsl:when test="/*/output = 'xml'">
            <alt:copy-of select="{/*/xpath-expr}"/>
          </xsl:when>
          <xsl:otherwise>
            <alt:value-of select="{/*/xpath-expr}"/>
          </xsl:otherwise>
        </xsl:choose>
      </alt:template>
    </alt:stylesheet>
  </xsl:template>

</xsl:stylesheet>
