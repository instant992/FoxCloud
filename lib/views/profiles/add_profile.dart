import 'package:flowvy/common/common.dart';
import 'package:flowvy/pages/scan.dart';
import 'package:flowvy/state.dart';
import 'package:flowvy/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AddProfileView extends StatelessWidget {
  final BuildContext context;
  final bool navigateToProfiles;

  const AddProfileView({
    super.key,
    required this.context,
    this.navigateToProfiles = true,
  });

  _handleAddProfileFormFile() async {
    globalState.appController.addProfileFormFile(navigateToProfiles: navigateToProfiles);
  }

  _handleAddProfileFormURL(String url) async {
    globalState.appController.addProfileFormURL(url, navigateToProfiles: navigateToProfiles);
  }

  _toScan() async {
    if (system.isDesktop) {
      globalState.appController.addProfileFormQrCode(navigateToProfiles: navigateToProfiles);
      return;
    }
    final url = await BaseNavigator.push(
      context,
      const ScanPage(),
    );
    if (url != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddProfileFormURL(url);
      });
    }
  }

  _toAdd() async {
    final url = await globalState.showCommonDialog<String>(
      child: InputDialog(
        autovalidateMode: AutovalidateMode.onUnfocus,
        title: appLocalizations.importFromURL,
        labelText: appLocalizations.url,
        value: '',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip("").trim();
          }
          if (!value.isUrl) {
            return appLocalizations.urlTip("").trim();
          }
          return null;
        },
      ),
    );
    if (url != null) {
      _handleAddProfileFormURL(url);
    }
  }

  @override
  Widget build(context) {
    return ListView(
      children: [
        ListItem(
          leading: const Icon(Icons.qr_code_scanner_rounded),
          title: Text(appLocalizations.qrcode),
          subtitle: Text(appLocalizations.qrcodeDesc),
          onTap: _toScan,
        ),
        ListItem(
          leading: const Icon(Icons.upload_file_rounded),
          title: Text(appLocalizations.file),
          subtitle: Text(appLocalizations.fileDesc),
          onTap: _handleAddProfileFormFile,
        ),
        ListItem(
          leading: const Icon(Icons.cloud_download_rounded),
          title: Text(appLocalizations.url),
          subtitle: Text(appLocalizations.urlDesc),
          onTap: _toAdd,
        ),
        ListItem(
          leading: const Icon(Icons.send_rounded),
          title: const Text('Нет ссылки? Получи её у бота'),
          subtitle: const Text('Откроется Telegram‑бот, который выдаст ссылку'),
          onTap: () {
            launchUrl(
              Uri.parse('https://t.me/foxicloudbot'), // 👈 замени на своего бота, если нужно
            );
            },
        )
      ],
    );
  }
}

class URLFormDialog extends StatefulWidget {
  const URLFormDialog({super.key});

  @override
  State<URLFormDialog> createState() => _URLFormDialogState();
}

class _URLFormDialogState extends State<URLFormDialog> {
  final urlController = TextEditingController();

  _handleAddProfileFormURL() async {
    final url = urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.importFromURL,
      actions: [
        TextButton(
          onPressed: _handleAddProfileFormURL,
          child: Text(appLocalizations.submit),
        )
      ],
      child: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              keyboardType: TextInputType.url,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) {
                _handleAddProfileFormURL();
              },
              onEditingComplete: _handleAddProfileFormURL,
              controller: urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: appLocalizations.url,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
