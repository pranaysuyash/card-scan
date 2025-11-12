import 'package:dio/dio.dart';
import '../../../models/contact.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';

/// CRM integration service for enterprise features
/// Supports Salesforce, HubSpot, and custom API endpoints
class CrmIntegrationService {
  final Dio _dio = Dio();

  // ============================================
  // SALESFORCE INTEGRATION
  // ============================================

  /// Export contact to Salesforce
  Future<Either<Failure, String>> exportToSalesforce({
    required Contact contact,
    required String accessToken,
    required String instanceUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$instanceUrl/services/data/v57.0/sobjects/Contact',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: _contactToSalesforcePayload(contact),
      );

      final contactId = response.data['id'] as String;
      return Right(contactId);
    } on DioException catch (e) {
      return Left(NetworkFailure(
        message: 'Failed to export to Salesforce: ${e.message}',
        code: e.response?.statusCode.toString(),
        details: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error exporting to Salesforce',
        details: e,
      ));
    }
  }

  /// Convert contact to Salesforce payload
  Map<String, dynamic> _contactToSalesforcePayload(Contact contact) {
    return {
      'FirstName': contact.givenName,
      'LastName': contact.familyName ?? contact.fullName,
      'Title': contact.title,
      'Company': contact.company,
      'Email': contact.emails.isNotEmpty ? contact.emails.first.value : null,
      'Phone': contact.phones.isNotEmpty ? contact.phones.first.value : null,
      'MobilePhone': contact.phones.length > 1 ? contact.phones[1].value : null,
      'Website': contact.website,
      'MailingStreet': contact.address,
      'Department': contact.department,
      'LeadSource': contact.leadSource,
      'Description': contact.notes.isNotEmpty ? contact.notes.first.content : null,
    };
  }

  // ============================================
  // HUBSPOT INTEGRATION
  // ============================================

  /// Export contact to HubSpot
  Future<Either<Failure, String>> exportToHubSpot({
    required Contact contact,
    required String apiKey,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.hubapi.com/contacts/v1/contact',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: _contactToHubSpotPayload(contact),
      );

      final contactId = response.data['vid'].toString();
      return Right(contactId);
    } on DioException catch (e) {
      return Left(NetworkFailure(
        message: 'Failed to export to HubSpot: ${e.message}',
        code: e.response?.statusCode.toString(),
        details: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error exporting to HubSpot',
        details: e,
      ));
    }
  }

  /// Convert contact to HubSpot payload
  Map<String, dynamic> _contactToHubSpotPayload(Contact contact) {
    return {
      'properties': [
        {
          'property': 'firstname',
          'value': contact.givenName,
        },
        {
          'property': 'lastname',
          'value': contact.familyName ?? contact.fullName,
        },
        {
          'property': 'email',
          'value': contact.emails.isNotEmpty ? contact.emails.first.value : '',
        },
        {
          'property': 'phone',
          'value': contact.phones.isNotEmpty ? contact.phones.first.value : '',
        },
        {
          'property': 'company',
          'value': contact.company,
        },
        {
          'property': 'jobtitle',
          'value': contact.title,
        },
        {
          'property': 'website',
          'value': contact.website,
        },
        {
          'property': 'address',
          'value': contact.address,
        },
      ],
    };
  }

  // ============================================
  // MICROSOFT DYNAMICS INTEGRATION
  // ============================================

  /// Export contact to Microsoft Dynamics
  Future<Either<Failure, String>> exportToDynamics({
    required Contact contact,
    required String accessToken,
    required String organizationUrl,
  }) async {
    try {
      final response = await _dio.post(
        '$organizationUrl/api/data/v9.2/contacts',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'OData-MaxVersion': '4.0',
            'OData-Version': '4.0',
          },
        ),
        data: _contactToDynamicsPayload(contact),
      );

      final contactId = response.data['contactid'] as String;
      return Right(contactId);
    } on DioException catch (e) {
      return Left(NetworkFailure(
        message: 'Failed to export to Dynamics: ${e.message}',
        code: e.response?.statusCode.toString(),
        details: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error exporting to Dynamics',
        details: e,
      ));
    }
  }

  /// Convert contact to Dynamics payload
  Map<String, dynamic> _contactToDynamicsPayload(Contact contact) {
    return {
      'firstname': contact.givenName,
      'lastname': contact.familyName ?? contact.fullName,
      'jobtitle': contact.title,
      'emailaddress1': contact.emails.isNotEmpty ? contact.emails.first.value : null,
      'telephone1': contact.phones.isNotEmpty ? contact.phones.first.value : null,
      'websiteurl': contact.website,
      'address1_composite': contact.address,
    };
  }

  // ============================================
  // CUSTOM WEBHOOK INTEGRATION
  // ============================================

  /// Send contact to custom webhook
  Future<Either<Failure, void>> sendToWebhook({
    required Contact contact,
    required String webhookUrl,
    Map<String, String>? headers,
  }) async {
    try {
      await _dio.post(
        webhookUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
        ),
        data: _contactToGenericPayload(contact),
      );

      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkFailure(
        message: 'Failed to send to webhook: ${e.message}',
        code: e.response?.statusCode.toString(),
        details: e,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error sending to webhook',
        details: e,
      ));
    }
  }

  /// Convert contact to generic JSON payload
  Map<String, dynamic> _contactToGenericPayload(Contact contact) {
    return {
      'id': contact.id,
      'fullName': contact.fullName,
      'givenName': contact.givenName,
      'familyName': contact.familyName,
      'title': contact.title,
      'company': contact.company,
      'emails': contact.emails.map((e) => {
            'value': e.value,
            'type': e.type,
          }).toList(),
      'phones': contact.phones.map((p) => {
            'value': p.value,
            'type': p.type,
          }).toList(),
      'website': contact.website,
      'address': contact.address,
      'linkedIn': contact.linkedIn,
      'twitter': contact.twitter,
      'facebook': contact.facebook,
      'instagram': contact.instagram,
      'github': contact.github,
      'department': contact.department,
      'jobFunction': contact.jobFunction,
      'industry': contact.industry,
      'skills': contact.skills,
      'tags': contact.tags,
      'contactScore': contact.contactScore,
      'createdAt': contact.createdAt.toIso8601String(),
      'updatedAt': contact.updatedAt.toIso8601String(),
    };
  }

  // ============================================
  // BATCH EXPORT
  // ============================================

  /// Export multiple contacts to CRM
  Future<Either<Failure, BatchExportResult>> batchExport({
    required List<Contact> contacts,
    required CrmProvider provider,
    required Map<String, String> credentials,
  }) async {
    final result = BatchExportResult();

    for (final contact in contacts) {
      Either<Failure, String> exportResult;

      switch (provider) {
        case CrmProvider.salesforce:
          exportResult = await exportToSalesforce(
            contact: contact,
            accessToken: credentials['accessToken']!,
            instanceUrl: credentials['instanceUrl']!,
          );
          break;
        case CrmProvider.hubspot:
          exportResult = await exportToHubSpot(
            contact: contact,
            apiKey: credentials['apiKey']!,
          );
          break;
        case CrmProvider.dynamics:
          exportResult = await exportToDynamics(
            contact: contact,
            accessToken: credentials['accessToken']!,
            organizationUrl: credentials['organizationUrl']!,
          );
          break;
      }

      exportResult.fold(
        (failure) {
          result.failed++;
          result.errors.add(failure);
        },
        (id) {
          result.succeeded++;
          result.exportedIds.add(id);
        },
      );
    }

    return Right(result);
  }
}

/// CRM providers
enum CrmProvider {
  salesforce,
  hubspot,
  dynamics,
}

/// Batch export result
class BatchExportResult {
  int succeeded = 0;
  int failed = 0;
  List<String> exportedIds = [];
  List<Failure> errors = [];

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => failed == 0;
  int get total => succeeded + failed;
}
