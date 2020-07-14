<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="template-doc-uri" select="'/main/getf/templates/html/offer.html'"/>
  <xsl:param name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="/">
    <div>
      <xsl:if test="not($template-doc)">
        <div>
          <p>
            <span style="color: red;"> Failed to load template document <xsl:value-of select="$template-doc-uri"/> </span>
          </p>
        </div>
        <xsl:message> Failed to load template document <xsl:value-of select="$template-doc-uri"/>
        </xsl:message>
      </xsl:if>
      <h4>Item <xsl:value-of select="/*/viewclass"/></h4>
      <div>
        <h4><xsl:value-of select="count(/*/action-findlist/findlist/item)"/> Actions</h4>
        <ul>
          <xsl:for-each select="/*/action-findlist/findlist/item">
            <li>
              <a href="javascript:xc.performAction(event, '{name}')">
                <xsl:value-of select="path"/>/<xsl:value-of select="name"/>
              </a>
            </li>
          </xsl:for-each>
        </ul>
      </div>
      <xsl:apply-templates select="$template-doc/*/xhtml:body/*"/>
    </div>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='tradeitems-headline']">
    <tr>
      <th class="aleft" colspan="2">Posten</th>
        <th class="aright">
          Anz.
        </th>
        <th class="aright">
          Preis
        </th>
        <th class="aright">
          Gesamt
        </th>
      </tr>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='tradeitems']">
    <xsl:for-each select="$this/*/cont/offer/tradeitem">
      <tr>
        <td>
          <xsl:number format="0"/>.
        </td>
        <td>
          <xsl:value-of select="desc"/>
        </td>
        <td>
          <xsl:value-of select="amount"/>
        </td>
        <td class="aright">
          <xsl:value-of select="format-number(price, '0.00')"/><xsl:value-of select="../cur"/>
        </td>
        <td class="aright">
          <xsl:value-of select="format-number(cost, '0.00')"/><xsl:value-of select="../cur"/>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-netto']">
    <tr>
      <td></td>
      <td>
        Netto
      </td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:value-of select="format-number($this/*/cont/offer/sum-netto, '0.00')"/><xsl:value-of select="$this/*/cont/offer/cur"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-taxes']">
    <tr>
      <td></td>
      <td>USt. <xsl:value-of select="$this/*/cont/offer/uststz*100"/>%</td>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <xsl:value-of select="format-number($this/*/cont/offer/sum-taxes, '0.00')"/><xsl:value-of select="$this/*/cont/offer/cur"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="xhtml:tr[@data-content='sum-brutto']">
    <tr>
      <td></td>
      <th>
        Brutto
      </th>
      <td>
      </td>
      <td>
      </td>
      <td class="aright">
        <b>
          <xsl:value-of select="format-number($this/*/cont/offer/sum-brutto, '0.00')"/><xsl:value-of select="$this/*/cont/offer/cur"/>
        </b>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
