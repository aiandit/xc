<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
                version="1.0">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:template match="/">
    <docinfo>
      <xsl:variable name="xroot" select="/x:*/x:cont/*"/>
      <document-element><xsl:value-of select="local-name($xroot)"/></document-element>
      <namespace><xsl:value-of select="namespace-uri($xroot)"/></namespace>
      <xsl:variable name="is-xc" select="namespace-uri($xroot) = 'http://ai-and-it.de/xmlns/2020/xc'"/>
      <is-xc><xsl:value-of select="$is-xc"/></is-xc>
      <text-length><xsl:value-of select="string-length($xroot)"/></text-length>
      <number-of-elements><xsl:value-of select="count($xroot//*)"/></number-of-elements>
      <number-of-text><xsl:value-of select="count($xroot//text())"/></number-of-text>
      <number-of-nodes><xsl:value-of select="count($xroot//node())"/></number-of-nodes>
    </docinfo>
  </xsl:template>

</xsl:stylesheet>
