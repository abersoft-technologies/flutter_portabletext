library flutter_portabletext_fork;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portabletext_fork/portable_text.dart';

class PortableTextRichText extends StatefulWidget {
  const PortableTextRichText({
    required this.portableText,
    this.onTapLink,
    this.mapStyle = const {
      'h1': TextStyle(fontSize: 24),
      'h2': TextStyle(fontSize: 22),
      'h3': TextStyle(fontSize: 20),
      'h4': TextStyle(fontSize: 18),
      'h5': TextStyle(fontSize: 16),
      'h6': TextStyle(fontSize: 14),
      'blockquote': TextStyle(fontSize: 12),
    },
    this.quoteStyle = const TextStyle(
      fontSize: 12,
    ),
    this.normalStyle = const TextStyle(fontSize: 10),
    this.externalLinkColor = const Color(0xFF0645AD),
    this.codeBackgroundColor = Colors.grey,
    this.externalLinkDecoration = TextDecoration.underline,
    super.key,
  });

  final List<PortableText> portableText;
  final Map<String, TextStyle> mapStyle;
  final TextStyle normalStyle;
  final TextStyle quoteStyle;
  final Color externalLinkColor;
  final Color codeBackgroundColor;
  final TextDecoration externalLinkDecoration;

  final void Function(String? value)? onTapLink;

  @override
  State<PortableTextRichText> createState() => _PortableTextRichTextState();
}

class _PortableTextRichTextState extends State<PortableTextRichText> {
  TextStyle applyStyles(
      TextStyle baseStyle, List<String>? styles, List<MarkDef> markDefs) {
    if (styles == null) return baseStyle;

    TextStyle updatedStyle = baseStyle;

    for (var style in styles) {
      switch (style) {
        case 'em':
          updatedStyle = updatedStyle.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'strong':
          updatedStyle = updatedStyle.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'underline':
          updatedStyle =
              updatedStyle.copyWith(decoration: TextDecoration.underline);
          break;
        case 'code':
          updatedStyle = updatedStyle.copyWith(
              backgroundColor: widget.codeBackgroundColor);
          break;
        case 'strike-through':
          updatedStyle =
              updatedStyle.copyWith(decoration: TextDecoration.lineThrough);
          break;
      }
    }

    for (var markDef in markDefs) {
      if (markDef.type == "link" && styles.contains(markDef.key)) {
        updatedStyle = updatedStyle.copyWith(
          color: widget.externalLinkColor,
          decoration: widget.externalLinkDecoration,
          decorationColor: widget.externalLinkColor,
        );
      }
    }

    return updatedStyle;
  }

  List<TextSpan> buildTextSpans(PortableText portableText) {
    return portableText.children.map((child) {
      void Function()? onTap = child.marks == null
          ? null
          : generateOnTapForLink(
              portableText.markDefs, child.marks!, widget.onTapLink);

      return TextSpan(
        recognizer: TapGestureRecognizer()..onTap = onTap,
        text: child.text,
        style: applyStyles(
          widget.mapStyle[portableText.style] ?? widget.normalStyle,
          child.marks,
          portableText.markDefs,
        ),
      );
    }).toList();
  }

  Widget buildBlockquote(List<TextSpan> textSpans) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey, width: 2)),
      ),
      child: Text.rich(TextSpan(children: textSpans)),
    );
  }

  Widget buildListItem(PortableText portableText, int index) {
    final List<TextSpan> textSpans = buildTextSpans(portableText);
    final String prefix = portableText.listItem == "bullet" ? "- " : "$index. ";

    return Text.rich(
      TextSpan(
        children: textSpans
            .map(
              (span) => TextSpan(
                text: '$prefix${span.text}',
                style: span.style,
              ),
            )
            .toList(),
        style: widget.normalStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int number = 1;

    final List<Widget> textWidgets = widget.portableText.map((portableText) {
      if (portableText.style == "blockquote") {
        return buildBlockquote(buildTextSpans(portableText));
      } else if (portableText.listItem != null) {
        return buildListItem(portableText, number++);
      } else {
        return Text.rich(
          TextSpan(
            children: buildTextSpans(portableText),
            style: widget.normalStyle,
          ),
        );
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: textWidgets,
    );
  }
}

void Function()? generateOnTapForLink(List<MarkDef> markDefs,
    List<String> marks, void Function(String value)? onTapLink) {
  for (var markDef in markDefs) {
    if (marks.contains(markDef.key)) {
      return () => onTapLink?.call(markDef.href!);
    }
  }
  return null;
}
