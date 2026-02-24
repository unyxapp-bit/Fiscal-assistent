// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FiscaisTable extends Fiscais with TableInfo<$FiscaisTable, FiscalTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscaisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _cpfMeta = const VerificationMeta('cpf');
  @override
  late final GeneratedColumn<String> cpf = GeneratedColumn<String>(
      'cpf', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 11, maxTextLength: 11),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _telefoneMeta =
      const VerificationMeta('telefone');
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
      'telefone', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 15),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _lojaNomeMeta =
      const VerificationMeta('lojaNome');
  @override
  late final GeneratedColumn<String> lojaNome = GeneratedColumn<String>(
      'loja_nome', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Minha Loja'));
  static const VerificationMeta _lojaHorarioAberturaMeta =
      const VerificationMeta('lojaHorarioAbertura');
  @override
  late final GeneratedColumn<String> lojaHorarioAbertura =
      GeneratedColumn<String>('loja_horario_abertura', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('08:00'));
  static const VerificationMeta _lojaHorarioFechamentoMeta =
      const VerificationMeta('lojaHorarioFechamento');
  @override
  late final GeneratedColumn<String> lojaHorarioFechamento =
      GeneratedColumn<String>('loja_horario_fechamento', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('21:00'));
  static const VerificationMeta _lojaHorarioDomingoAberturaMeta =
      const VerificationMeta('lojaHorarioDomingoAbertura');
  @override
  late final GeneratedColumn<String> lojaHorarioDomingoAbertura =
      GeneratedColumn<String>(
          'loja_horario_domingo_abertura', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('08:00'));
  static const VerificationMeta _lojaHorarioDomingoFechamentoMeta =
      const VerificationMeta('lojaHorarioDomingoFechamento');
  @override
  late final GeneratedColumn<String> lojaHorarioDomingoFechamento =
      GeneratedColumn<String>(
          'loja_horario_domingo_fechamento', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('13:00'));
  static const VerificationMeta _preferenciasMeta =
      const VerificationMeta('preferencias');
  @override
  late final GeneratedColumn<String> preferencias = GeneratedColumn<String>(
      'preferencias', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        nome,
        cpf,
        telefone,
        lojaNome,
        lojaHorarioAbertura,
        lojaHorarioFechamento,
        lojaHorarioDomingoAbertura,
        lojaHorarioDomingoFechamento,
        preferencias,
        createdAt,
        updatedAt,
        lastSyncAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscais';
  @override
  VerificationContext validateIntegrity(Insertable<FiscalTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('cpf')) {
      context.handle(
          _cpfMeta, cpf.isAcceptableOrUnknown(data['cpf']!, _cpfMeta));
    }
    if (data.containsKey('telefone')) {
      context.handle(_telefoneMeta,
          telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta));
    }
    if (data.containsKey('loja_nome')) {
      context.handle(_lojaNomeMeta,
          lojaNome.isAcceptableOrUnknown(data['loja_nome']!, _lojaNomeMeta));
    }
    if (data.containsKey('loja_horario_abertura')) {
      context.handle(
          _lojaHorarioAberturaMeta,
          lojaHorarioAbertura.isAcceptableOrUnknown(
              data['loja_horario_abertura']!, _lojaHorarioAberturaMeta));
    }
    if (data.containsKey('loja_horario_fechamento')) {
      context.handle(
          _lojaHorarioFechamentoMeta,
          lojaHorarioFechamento.isAcceptableOrUnknown(
              data['loja_horario_fechamento']!, _lojaHorarioFechamentoMeta));
    }
    if (data.containsKey('loja_horario_domingo_abertura')) {
      context.handle(
          _lojaHorarioDomingoAberturaMeta,
          lojaHorarioDomingoAbertura.isAcceptableOrUnknown(
              data['loja_horario_domingo_abertura']!,
              _lojaHorarioDomingoAberturaMeta));
    }
    if (data.containsKey('loja_horario_domingo_fechamento')) {
      context.handle(
          _lojaHorarioDomingoFechamentoMeta,
          lojaHorarioDomingoFechamento.isAcceptableOrUnknown(
              data['loja_horario_domingo_fechamento']!,
              _lojaHorarioDomingoFechamentoMeta));
    }
    if (data.containsKey('preferencias')) {
      context.handle(
          _preferenciasMeta,
          preferencias.isAcceptableOrUnknown(
              data['preferencias']!, _preferenciasMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      cpf: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cpf']),
      telefone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}telefone']),
      lojaNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loja_nome'])!,
      lojaHorarioAbertura: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}loja_horario_abertura'])!,
      lojaHorarioFechamento: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}loja_horario_fechamento'])!,
      lojaHorarioDomingoAbertura: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}loja_horario_domingo_abertura'])!,
      lojaHorarioDomingoFechamento: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}loja_horario_domingo_fechamento'])!,
      preferencias: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preferencias']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $FiscaisTable createAlias(String alias) {
    return $FiscaisTable(attachedDatabase, alias);
  }
}

class FiscalTable extends DataClass implements Insertable<FiscalTable> {
  final String id;
  final String userId;
  final String nome;
  final String? cpf;
  final String? telefone;
  final String lojaNome;
  final String lojaHorarioAbertura;
  final String lojaHorarioFechamento;
  final String lojaHorarioDomingoAbertura;
  final String lojaHorarioDomingoFechamento;
  final String? preferencias;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;
  const FiscalTable(
      {required this.id,
      required this.userId,
      required this.nome,
      this.cpf,
      this.telefone,
      required this.lojaNome,
      required this.lojaHorarioAbertura,
      required this.lojaHorarioFechamento,
      required this.lojaHorarioDomingoAbertura,
      required this.lojaHorarioDomingoFechamento,
      this.preferencias,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || cpf != null) {
      map['cpf'] = Variable<String>(cpf);
    }
    if (!nullToAbsent || telefone != null) {
      map['telefone'] = Variable<String>(telefone);
    }
    map['loja_nome'] = Variable<String>(lojaNome);
    map['loja_horario_abertura'] = Variable<String>(lojaHorarioAbertura);
    map['loja_horario_fechamento'] = Variable<String>(lojaHorarioFechamento);
    map['loja_horario_domingo_abertura'] =
        Variable<String>(lojaHorarioDomingoAbertura);
    map['loja_horario_domingo_fechamento'] =
        Variable<String>(lojaHorarioDomingoFechamento);
    if (!nullToAbsent || preferencias != null) {
      map['preferencias'] = Variable<String>(preferencias);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  FiscaisCompanion toCompanion(bool nullToAbsent) {
    return FiscaisCompanion(
      id: Value(id),
      userId: Value(userId),
      nome: Value(nome),
      cpf: cpf == null && nullToAbsent ? const Value.absent() : Value(cpf),
      telefone: telefone == null && nullToAbsent
          ? const Value.absent()
          : Value(telefone),
      lojaNome: Value(lojaNome),
      lojaHorarioAbertura: Value(lojaHorarioAbertura),
      lojaHorarioFechamento: Value(lojaHorarioFechamento),
      lojaHorarioDomingoAbertura: Value(lojaHorarioDomingoAbertura),
      lojaHorarioDomingoFechamento: Value(lojaHorarioDomingoFechamento),
      preferencias: preferencias == null && nullToAbsent
          ? const Value.absent()
          : Value(preferencias),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory FiscalTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalTable(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      nome: serializer.fromJson<String>(json['nome']),
      cpf: serializer.fromJson<String?>(json['cpf']),
      telefone: serializer.fromJson<String?>(json['telefone']),
      lojaNome: serializer.fromJson<String>(json['lojaNome']),
      lojaHorarioAbertura:
          serializer.fromJson<String>(json['lojaHorarioAbertura']),
      lojaHorarioFechamento:
          serializer.fromJson<String>(json['lojaHorarioFechamento']),
      lojaHorarioDomingoAbertura:
          serializer.fromJson<String>(json['lojaHorarioDomingoAbertura']),
      lojaHorarioDomingoFechamento:
          serializer.fromJson<String>(json['lojaHorarioDomingoFechamento']),
      preferencias: serializer.fromJson<String?>(json['preferencias']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'nome': serializer.toJson<String>(nome),
      'cpf': serializer.toJson<String?>(cpf),
      'telefone': serializer.toJson<String?>(telefone),
      'lojaNome': serializer.toJson<String>(lojaNome),
      'lojaHorarioAbertura': serializer.toJson<String>(lojaHorarioAbertura),
      'lojaHorarioFechamento': serializer.toJson<String>(lojaHorarioFechamento),
      'lojaHorarioDomingoAbertura':
          serializer.toJson<String>(lojaHorarioDomingoAbertura),
      'lojaHorarioDomingoFechamento':
          serializer.toJson<String>(lojaHorarioDomingoFechamento),
      'preferencias': serializer.toJson<String?>(preferencias),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  FiscalTable copyWith(
          {String? id,
          String? userId,
          String? nome,
          Value<String?> cpf = const Value.absent(),
          Value<String?> telefone = const Value.absent(),
          String? lojaNome,
          String? lojaHorarioAbertura,
          String? lojaHorarioFechamento,
          String? lojaHorarioDomingoAbertura,
          String? lojaHorarioDomingoFechamento,
          Value<String?> preferencias = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      FiscalTable(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        nome: nome ?? this.nome,
        cpf: cpf.present ? cpf.value : this.cpf,
        telefone: telefone.present ? telefone.value : this.telefone,
        lojaNome: lojaNome ?? this.lojaNome,
        lojaHorarioAbertura: lojaHorarioAbertura ?? this.lojaHorarioAbertura,
        lojaHorarioFechamento:
            lojaHorarioFechamento ?? this.lojaHorarioFechamento,
        lojaHorarioDomingoAbertura:
            lojaHorarioDomingoAbertura ?? this.lojaHorarioDomingoAbertura,
        lojaHorarioDomingoFechamento:
            lojaHorarioDomingoFechamento ?? this.lojaHorarioDomingoFechamento,
        preferencias:
            preferencias.present ? preferencias.value : this.preferencias,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  FiscalTable copyWithCompanion(FiscaisCompanion data) {
    return FiscalTable(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      nome: data.nome.present ? data.nome.value : this.nome,
      cpf: data.cpf.present ? data.cpf.value : this.cpf,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      lojaNome: data.lojaNome.present ? data.lojaNome.value : this.lojaNome,
      lojaHorarioAbertura: data.lojaHorarioAbertura.present
          ? data.lojaHorarioAbertura.value
          : this.lojaHorarioAbertura,
      lojaHorarioFechamento: data.lojaHorarioFechamento.present
          ? data.lojaHorarioFechamento.value
          : this.lojaHorarioFechamento,
      lojaHorarioDomingoAbertura: data.lojaHorarioDomingoAbertura.present
          ? data.lojaHorarioDomingoAbertura.value
          : this.lojaHorarioDomingoAbertura,
      lojaHorarioDomingoFechamento: data.lojaHorarioDomingoFechamento.present
          ? data.lojaHorarioDomingoFechamento.value
          : this.lojaHorarioDomingoFechamento,
      preferencias: data.preferencias.present
          ? data.preferencias.value
          : this.preferencias,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalTable(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('telefone: $telefone, ')
          ..write('lojaNome: $lojaNome, ')
          ..write('lojaHorarioAbertura: $lojaHorarioAbertura, ')
          ..write('lojaHorarioFechamento: $lojaHorarioFechamento, ')
          ..write('lojaHorarioDomingoAbertura: $lojaHorarioDomingoAbertura, ')
          ..write(
              'lojaHorarioDomingoFechamento: $lojaHorarioDomingoFechamento, ')
          ..write('preferencias: $preferencias, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      nome,
      cpf,
      telefone,
      lojaNome,
      lojaHorarioAbertura,
      lojaHorarioFechamento,
      lojaHorarioDomingoAbertura,
      lojaHorarioDomingoFechamento,
      preferencias,
      createdAt,
      updatedAt,
      lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalTable &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.nome == this.nome &&
          other.cpf == this.cpf &&
          other.telefone == this.telefone &&
          other.lojaNome == this.lojaNome &&
          other.lojaHorarioAbertura == this.lojaHorarioAbertura &&
          other.lojaHorarioFechamento == this.lojaHorarioFechamento &&
          other.lojaHorarioDomingoAbertura == this.lojaHorarioDomingoAbertura &&
          other.lojaHorarioDomingoFechamento ==
              this.lojaHorarioDomingoFechamento &&
          other.preferencias == this.preferencias &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class FiscaisCompanion extends UpdateCompanion<FiscalTable> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> nome;
  final Value<String?> cpf;
  final Value<String?> telefone;
  final Value<String> lojaNome;
  final Value<String> lojaHorarioAbertura;
  final Value<String> lojaHorarioFechamento;
  final Value<String> lojaHorarioDomingoAbertura;
  final Value<String> lojaHorarioDomingoFechamento;
  final Value<String?> preferencias;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const FiscaisCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.nome = const Value.absent(),
    this.cpf = const Value.absent(),
    this.telefone = const Value.absent(),
    this.lojaNome = const Value.absent(),
    this.lojaHorarioAbertura = const Value.absent(),
    this.lojaHorarioFechamento = const Value.absent(),
    this.lojaHorarioDomingoAbertura = const Value.absent(),
    this.lojaHorarioDomingoFechamento = const Value.absent(),
    this.preferencias = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FiscaisCompanion.insert({
    required String id,
    required String userId,
    required String nome,
    this.cpf = const Value.absent(),
    this.telefone = const Value.absent(),
    this.lojaNome = const Value.absent(),
    this.lojaHorarioAbertura = const Value.absent(),
    this.lojaHorarioFechamento = const Value.absent(),
    this.lojaHorarioDomingoAbertura = const Value.absent(),
    this.lojaHorarioDomingoFechamento = const Value.absent(),
    this.preferencias = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        nome = Value(nome);
  static Insertable<FiscalTable> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? nome,
    Expression<String>? cpf,
    Expression<String>? telefone,
    Expression<String>? lojaNome,
    Expression<String>? lojaHorarioAbertura,
    Expression<String>? lojaHorarioFechamento,
    Expression<String>? lojaHorarioDomingoAbertura,
    Expression<String>? lojaHorarioDomingoFechamento,
    Expression<String>? preferencias,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (nome != null) 'nome': nome,
      if (cpf != null) 'cpf': cpf,
      if (telefone != null) 'telefone': telefone,
      if (lojaNome != null) 'loja_nome': lojaNome,
      if (lojaHorarioAbertura != null)
        'loja_horario_abertura': lojaHorarioAbertura,
      if (lojaHorarioFechamento != null)
        'loja_horario_fechamento': lojaHorarioFechamento,
      if (lojaHorarioDomingoAbertura != null)
        'loja_horario_domingo_abertura': lojaHorarioDomingoAbertura,
      if (lojaHorarioDomingoFechamento != null)
        'loja_horario_domingo_fechamento': lojaHorarioDomingoFechamento,
      if (preferencias != null) 'preferencias': preferencias,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FiscaisCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? nome,
      Value<String?>? cpf,
      Value<String?>? telefone,
      Value<String>? lojaNome,
      Value<String>? lojaHorarioAbertura,
      Value<String>? lojaHorarioFechamento,
      Value<String>? lojaHorarioDomingoAbertura,
      Value<String>? lojaHorarioDomingoFechamento,
      Value<String?>? preferencias,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return FiscaisCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      lojaNome: lojaNome ?? this.lojaNome,
      lojaHorarioAbertura: lojaHorarioAbertura ?? this.lojaHorarioAbertura,
      lojaHorarioFechamento:
          lojaHorarioFechamento ?? this.lojaHorarioFechamento,
      lojaHorarioDomingoAbertura:
          lojaHorarioDomingoAbertura ?? this.lojaHorarioDomingoAbertura,
      lojaHorarioDomingoFechamento:
          lojaHorarioDomingoFechamento ?? this.lojaHorarioDomingoFechamento,
      preferencias: preferencias ?? this.preferencias,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (cpf.present) {
      map['cpf'] = Variable<String>(cpf.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (lojaNome.present) {
      map['loja_nome'] = Variable<String>(lojaNome.value);
    }
    if (lojaHorarioAbertura.present) {
      map['loja_horario_abertura'] =
          Variable<String>(lojaHorarioAbertura.value);
    }
    if (lojaHorarioFechamento.present) {
      map['loja_horario_fechamento'] =
          Variable<String>(lojaHorarioFechamento.value);
    }
    if (lojaHorarioDomingoAbertura.present) {
      map['loja_horario_domingo_abertura'] =
          Variable<String>(lojaHorarioDomingoAbertura.value);
    }
    if (lojaHorarioDomingoFechamento.present) {
      map['loja_horario_domingo_fechamento'] =
          Variable<String>(lojaHorarioDomingoFechamento.value);
    }
    if (preferencias.present) {
      map['preferencias'] = Variable<String>(preferencias.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscaisCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nome: $nome, ')
          ..write('cpf: $cpf, ')
          ..write('telefone: $telefone, ')
          ..write('lojaNome: $lojaNome, ')
          ..write('lojaHorarioAbertura: $lojaHorarioAbertura, ')
          ..write('lojaHorarioFechamento: $lojaHorarioFechamento, ')
          ..write('lojaHorarioDomingoAbertura: $lojaHorarioDomingoAbertura, ')
          ..write(
              'lojaHorarioDomingoFechamento: $lojaHorarioDomingoFechamento, ')
          ..write('preferencias: $preferencias, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ColaboradoresTable extends Colaboradores
    with TableInfo<$ColaboradoresTable, ColaboradorTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColaboradoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fiscalIdMeta =
      const VerificationMeta('fiscalId');
  @override
  late final GeneratedColumn<String> fiscalId = GeneratedColumn<String>(
      'fiscal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _departamentoMeta =
      const VerificationMeta('departamento');
  @override
  late final GeneratedColumn<String> departamento = GeneratedColumn<String>(
      'departamento', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _avatarIniciaisMeta =
      const VerificationMeta('avatarIniciais');
  @override
  late final GeneratedColumn<String> avatarIniciais = GeneratedColumn<String>(
      'avatar_iniciais', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 2),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fiscalId,
        nome,
        departamento,
        avatarIniciais,
        ativo,
        observacoes,
        createdAt,
        updatedAt,
        lastSyncAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'colaboradores';
  @override
  VerificationContext validateIntegrity(Insertable<ColaboradorTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fiscal_id')) {
      context.handle(_fiscalIdMeta,
          fiscalId.isAcceptableOrUnknown(data['fiscal_id']!, _fiscalIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('departamento')) {
      context.handle(
          _departamentoMeta,
          departamento.isAcceptableOrUnknown(
              data['departamento']!, _departamentoMeta));
    } else if (isInserting) {
      context.missing(_departamentoMeta);
    }
    if (data.containsKey('avatar_iniciais')) {
      context.handle(
          _avatarIniciaisMeta,
          avatarIniciais.isAcceptableOrUnknown(
              data['avatar_iniciais']!, _avatarIniciaisMeta));
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ColaboradorTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ColaboradorTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fiscalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fiscal_id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      departamento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}departamento'])!,
      avatarIniciais: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_iniciais']),
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $ColaboradoresTable createAlias(String alias) {
    return $ColaboradoresTable(attachedDatabase, alias);
  }
}

class ColaboradorTable extends DataClass
    implements Insertable<ColaboradorTable> {
  final String id;
  final String fiscalId;
  final String nome;
  final String departamento;
  final String? avatarIniciais;
  final bool ativo;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;
  const ColaboradorTable(
      {required this.id,
      required this.fiscalId,
      required this.nome,
      required this.departamento,
      this.avatarIniciais,
      required this.ativo,
      this.observacoes,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fiscal_id'] = Variable<String>(fiscalId);
    map['nome'] = Variable<String>(nome);
    map['departamento'] = Variable<String>(departamento);
    if (!nullToAbsent || avatarIniciais != null) {
      map['avatar_iniciais'] = Variable<String>(avatarIniciais);
    }
    map['ativo'] = Variable<bool>(ativo);
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  ColaboradoresCompanion toCompanion(bool nullToAbsent) {
    return ColaboradoresCompanion(
      id: Value(id),
      fiscalId: Value(fiscalId),
      nome: Value(nome),
      departamento: Value(departamento),
      avatarIniciais: avatarIniciais == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarIniciais),
      ativo: Value(ativo),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory ColaboradorTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ColaboradorTable(
      id: serializer.fromJson<String>(json['id']),
      fiscalId: serializer.fromJson<String>(json['fiscalId']),
      nome: serializer.fromJson<String>(json['nome']),
      departamento: serializer.fromJson<String>(json['departamento']),
      avatarIniciais: serializer.fromJson<String?>(json['avatarIniciais']),
      ativo: serializer.fromJson<bool>(json['ativo']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fiscalId': serializer.toJson<String>(fiscalId),
      'nome': serializer.toJson<String>(nome),
      'departamento': serializer.toJson<String>(departamento),
      'avatarIniciais': serializer.toJson<String?>(avatarIniciais),
      'ativo': serializer.toJson<bool>(ativo),
      'observacoes': serializer.toJson<String?>(observacoes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  ColaboradorTable copyWith(
          {String? id,
          String? fiscalId,
          String? nome,
          String? departamento,
          Value<String?> avatarIniciais = const Value.absent(),
          bool? ativo,
          Value<String?> observacoes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      ColaboradorTable(
        id: id ?? this.id,
        fiscalId: fiscalId ?? this.fiscalId,
        nome: nome ?? this.nome,
        departamento: departamento ?? this.departamento,
        avatarIniciais:
            avatarIniciais.present ? avatarIniciais.value : this.avatarIniciais,
        ativo: ativo ?? this.ativo,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  ColaboradorTable copyWithCompanion(ColaboradoresCompanion data) {
    return ColaboradorTable(
      id: data.id.present ? data.id.value : this.id,
      fiscalId: data.fiscalId.present ? data.fiscalId.value : this.fiscalId,
      nome: data.nome.present ? data.nome.value : this.nome,
      departamento: data.departamento.present
          ? data.departamento.value
          : this.departamento,
      avatarIniciais: data.avatarIniciais.present
          ? data.avatarIniciais.value
          : this.avatarIniciais,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ColaboradorTable(')
          ..write('id: $id, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('nome: $nome, ')
          ..write('departamento: $departamento, ')
          ..write('avatarIniciais: $avatarIniciais, ')
          ..write('ativo: $ativo, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fiscalId, nome, departamento,
      avatarIniciais, ativo, observacoes, createdAt, updatedAt, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ColaboradorTable &&
          other.id == this.id &&
          other.fiscalId == this.fiscalId &&
          other.nome == this.nome &&
          other.departamento == this.departamento &&
          other.avatarIniciais == this.avatarIniciais &&
          other.ativo == this.ativo &&
          other.observacoes == this.observacoes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class ColaboradoresCompanion extends UpdateCompanion<ColaboradorTable> {
  final Value<String> id;
  final Value<String> fiscalId;
  final Value<String> nome;
  final Value<String> departamento;
  final Value<String?> avatarIniciais;
  final Value<bool> ativo;
  final Value<String?> observacoes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const ColaboradoresCompanion({
    this.id = const Value.absent(),
    this.fiscalId = const Value.absent(),
    this.nome = const Value.absent(),
    this.departamento = const Value.absent(),
    this.avatarIniciais = const Value.absent(),
    this.ativo = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColaboradoresCompanion.insert({
    required String id,
    required String fiscalId,
    required String nome,
    required String departamento,
    this.avatarIniciais = const Value.absent(),
    this.ativo = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fiscalId = Value(fiscalId),
        nome = Value(nome),
        departamento = Value(departamento);
  static Insertable<ColaboradorTable> custom({
    Expression<String>? id,
    Expression<String>? fiscalId,
    Expression<String>? nome,
    Expression<String>? departamento,
    Expression<String>? avatarIniciais,
    Expression<bool>? ativo,
    Expression<String>? observacoes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fiscalId != null) 'fiscal_id': fiscalId,
      if (nome != null) 'nome': nome,
      if (departamento != null) 'departamento': departamento,
      if (avatarIniciais != null) 'avatar_iniciais': avatarIniciais,
      if (ativo != null) 'ativo': ativo,
      if (observacoes != null) 'observacoes': observacoes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColaboradoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? fiscalId,
      Value<String>? nome,
      Value<String>? departamento,
      Value<String?>? avatarIniciais,
      Value<bool>? ativo,
      Value<String?>? observacoes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return ColaboradoresCompanion(
      id: id ?? this.id,
      fiscalId: fiscalId ?? this.fiscalId,
      nome: nome ?? this.nome,
      departamento: departamento ?? this.departamento,
      avatarIniciais: avatarIniciais ?? this.avatarIniciais,
      ativo: ativo ?? this.ativo,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fiscalId.present) {
      map['fiscal_id'] = Variable<String>(fiscalId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (departamento.present) {
      map['departamento'] = Variable<String>(departamento.value);
    }
    if (avatarIniciais.present) {
      map['avatar_iniciais'] = Variable<String>(avatarIniciais.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ColaboradoresCompanion(')
          ..write('id: $id, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('nome: $nome, ')
          ..write('departamento: $departamento, ')
          ..write('avatarIniciais: $avatarIniciais, ')
          ..write('ativo: $ativo, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaixasTable extends Caixas with TableInfo<$CaixasTable, CaixaTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaixasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fiscalIdMeta =
      const VerificationMeta('fiscalId');
  @override
  late final GeneratedColumn<String> fiscalId = GeneratedColumn<String>(
      'fiscal_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<int> numero = GeneratedColumn<int>(
      'numero', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _emManutencaoMeta =
      const VerificationMeta('emManutencao');
  @override
  late final GeneratedColumn<bool> emManutencao = GeneratedColumn<bool>(
      'em_manutencao', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("em_manutencao" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fiscalId,
        numero,
        tipo,
        ativo,
        emManutencao,
        observacoes,
        createdAt,
        updatedAt,
        lastSyncAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caixas';
  @override
  VerificationContext validateIntegrity(Insertable<CaixaTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fiscal_id')) {
      context.handle(_fiscalIdMeta,
          fiscalId.isAcceptableOrUnknown(data['fiscal_id']!, _fiscalIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalIdMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(_numeroMeta,
          numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta));
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    if (data.containsKey('em_manutencao')) {
      context.handle(
          _emManutencaoMeta,
          emManutencao.isAcceptableOrUnknown(
              data['em_manutencao']!, _emManutencaoMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {fiscalId, numero},
      ];
  @override
  CaixaTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaixaTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fiscalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fiscal_id'])!,
      numero: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}numero'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
      emManutencao: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}em_manutencao'])!,
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $CaixasTable createAlias(String alias) {
    return $CaixasTable(attachedDatabase, alias);
  }
}

class CaixaTable extends DataClass implements Insertable<CaixaTable> {
  final String id;
  final String fiscalId;
  final int numero;
  final String tipo;
  final bool ativo;
  final bool emManutencao;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;
  const CaixaTable(
      {required this.id,
      required this.fiscalId,
      required this.numero,
      required this.tipo,
      required this.ativo,
      required this.emManutencao,
      this.observacoes,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fiscal_id'] = Variable<String>(fiscalId);
    map['numero'] = Variable<int>(numero);
    map['tipo'] = Variable<String>(tipo);
    map['ativo'] = Variable<bool>(ativo);
    map['em_manutencao'] = Variable<bool>(emManutencao);
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  CaixasCompanion toCompanion(bool nullToAbsent) {
    return CaixasCompanion(
      id: Value(id),
      fiscalId: Value(fiscalId),
      numero: Value(numero),
      tipo: Value(tipo),
      ativo: Value(ativo),
      emManutencao: Value(emManutencao),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory CaixaTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaixaTable(
      id: serializer.fromJson<String>(json['id']),
      fiscalId: serializer.fromJson<String>(json['fiscalId']),
      numero: serializer.fromJson<int>(json['numero']),
      tipo: serializer.fromJson<String>(json['tipo']),
      ativo: serializer.fromJson<bool>(json['ativo']),
      emManutencao: serializer.fromJson<bool>(json['emManutencao']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fiscalId': serializer.toJson<String>(fiscalId),
      'numero': serializer.toJson<int>(numero),
      'tipo': serializer.toJson<String>(tipo),
      'ativo': serializer.toJson<bool>(ativo),
      'emManutencao': serializer.toJson<bool>(emManutencao),
      'observacoes': serializer.toJson<String?>(observacoes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  CaixaTable copyWith(
          {String? id,
          String? fiscalId,
          int? numero,
          String? tipo,
          bool? ativo,
          bool? emManutencao,
          Value<String?> observacoes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      CaixaTable(
        id: id ?? this.id,
        fiscalId: fiscalId ?? this.fiscalId,
        numero: numero ?? this.numero,
        tipo: tipo ?? this.tipo,
        ativo: ativo ?? this.ativo,
        emManutencao: emManutencao ?? this.emManutencao,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  CaixaTable copyWithCompanion(CaixasCompanion data) {
    return CaixaTable(
      id: data.id.present ? data.id.value : this.id,
      fiscalId: data.fiscalId.present ? data.fiscalId.value : this.fiscalId,
      numero: data.numero.present ? data.numero.value : this.numero,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
      emManutencao: data.emManutencao.present
          ? data.emManutencao.value
          : this.emManutencao,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaixaTable(')
          ..write('id: $id, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('numero: $numero, ')
          ..write('tipo: $tipo, ')
          ..write('ativo: $ativo, ')
          ..write('emManutencao: $emManutencao, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fiscalId, numero, tipo, ativo,
      emManutencao, observacoes, createdAt, updatedAt, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaixaTable &&
          other.id == this.id &&
          other.fiscalId == this.fiscalId &&
          other.numero == this.numero &&
          other.tipo == this.tipo &&
          other.ativo == this.ativo &&
          other.emManutencao == this.emManutencao &&
          other.observacoes == this.observacoes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class CaixasCompanion extends UpdateCompanion<CaixaTable> {
  final Value<String> id;
  final Value<String> fiscalId;
  final Value<int> numero;
  final Value<String> tipo;
  final Value<bool> ativo;
  final Value<bool> emManutencao;
  final Value<String?> observacoes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const CaixasCompanion({
    this.id = const Value.absent(),
    this.fiscalId = const Value.absent(),
    this.numero = const Value.absent(),
    this.tipo = const Value.absent(),
    this.ativo = const Value.absent(),
    this.emManutencao = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaixasCompanion.insert({
    required String id,
    required String fiscalId,
    required int numero,
    required String tipo,
    this.ativo = const Value.absent(),
    this.emManutencao = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fiscalId = Value(fiscalId),
        numero = Value(numero),
        tipo = Value(tipo);
  static Insertable<CaixaTable> custom({
    Expression<String>? id,
    Expression<String>? fiscalId,
    Expression<int>? numero,
    Expression<String>? tipo,
    Expression<bool>? ativo,
    Expression<bool>? emManutencao,
    Expression<String>? observacoes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fiscalId != null) 'fiscal_id': fiscalId,
      if (numero != null) 'numero': numero,
      if (tipo != null) 'tipo': tipo,
      if (ativo != null) 'ativo': ativo,
      if (emManutencao != null) 'em_manutencao': emManutencao,
      if (observacoes != null) 'observacoes': observacoes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaixasCompanion copyWith(
      {Value<String>? id,
      Value<String>? fiscalId,
      Value<int>? numero,
      Value<String>? tipo,
      Value<bool>? ativo,
      Value<bool>? emManutencao,
      Value<String?>? observacoes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return CaixasCompanion(
      id: id ?? this.id,
      fiscalId: fiscalId ?? this.fiscalId,
      numero: numero ?? this.numero,
      tipo: tipo ?? this.tipo,
      ativo: ativo ?? this.ativo,
      emManutencao: emManutencao ?? this.emManutencao,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fiscalId.present) {
      map['fiscal_id'] = Variable<String>(fiscalId.value);
    }
    if (numero.present) {
      map['numero'] = Variable<int>(numero.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    if (emManutencao.present) {
      map['em_manutencao'] = Variable<bool>(emManutencao.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaixasCompanion(')
          ..write('id: $id, ')
          ..write('fiscalId: $fiscalId, ')
          ..write('numero: $numero, ')
          ..write('tipo: $tipo, ')
          ..write('ativo: $ativo, ')
          ..write('emManutencao: $emManutencao, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TurnosEscalaTable extends TurnosEscala
    with TableInfo<$TurnosEscalaTable, TurnoTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TurnosEscalaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _escalaIdMeta =
      const VerificationMeta('escalaId');
  @override
  late final GeneratedColumn<String> escalaId = GeneratedColumn<String>(
      'escala_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colaboradorIdMeta =
      const VerificationMeta('colaboradorId');
  @override
  late final GeneratedColumn<String> colaboradorId = GeneratedColumn<String>(
      'colaborador_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
      'data', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _entradaPrevistaMeta =
      const VerificationMeta('entradaPrevista');
  @override
  late final GeneratedColumn<String> entradaPrevista = GeneratedColumn<String>(
      'entrada_prevista', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _intervaloPrevistoMeta =
      const VerificationMeta('intervaloPrevisto');
  @override
  late final GeneratedColumn<String> intervaloPrevisto =
      GeneratedColumn<String>('intervalo_previsto', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _retornoPrevistoMeta =
      const VerificationMeta('retornoPrevisto');
  @override
  late final GeneratedColumn<String> retornoPrevisto = GeneratedColumn<String>(
      'retorno_previsto', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _saidaPrevistaMeta =
      const VerificationMeta('saidaPrevista');
  @override
  late final GeneratedColumn<String> saidaPrevista = GeneratedColumn<String>(
      'saida_prevista', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ehFolgaMeta =
      const VerificationMeta('ehFolga');
  @override
  late final GeneratedColumn<bool> ehFolga = GeneratedColumn<bool>(
      'eh_folga', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("eh_folga" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        escalaId,
        colaboradorId,
        data,
        entradaPrevista,
        intervaloPrevisto,
        retornoPrevisto,
        saidaPrevista,
        ehFolga,
        createdAt,
        updatedAt,
        lastSyncAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'turnos_escala';
  @override
  VerificationContext validateIntegrity(Insertable<TurnoTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('escala_id')) {
      context.handle(_escalaIdMeta,
          escalaId.isAcceptableOrUnknown(data['escala_id']!, _escalaIdMeta));
    } else if (isInserting) {
      context.missing(_escalaIdMeta);
    }
    if (data.containsKey('colaborador_id')) {
      context.handle(
          _colaboradorIdMeta,
          colaboradorId.isAcceptableOrUnknown(
              data['colaborador_id']!, _colaboradorIdMeta));
    } else if (isInserting) {
      context.missing(_colaboradorIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('entrada_prevista')) {
      context.handle(
          _entradaPrevistaMeta,
          entradaPrevista.isAcceptableOrUnknown(
              data['entrada_prevista']!, _entradaPrevistaMeta));
    }
    if (data.containsKey('intervalo_previsto')) {
      context.handle(
          _intervaloPrevistoMeta,
          intervaloPrevisto.isAcceptableOrUnknown(
              data['intervalo_previsto']!, _intervaloPrevistoMeta));
    }
    if (data.containsKey('retorno_previsto')) {
      context.handle(
          _retornoPrevistoMeta,
          retornoPrevisto.isAcceptableOrUnknown(
              data['retorno_previsto']!, _retornoPrevistoMeta));
    }
    if (data.containsKey('saida_prevista')) {
      context.handle(
          _saidaPrevistaMeta,
          saidaPrevista.isAcceptableOrUnknown(
              data['saida_prevista']!, _saidaPrevistaMeta));
    }
    if (data.containsKey('eh_folga')) {
      context.handle(_ehFolgaMeta,
          ehFolga.isAcceptableOrUnknown(data['eh_folga']!, _ehFolgaMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {colaboradorId, data},
      ];
  @override
  TurnoTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TurnoTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      escalaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}escala_id'])!,
      colaboradorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colaborador_id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}data'])!,
      entradaPrevista: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}entrada_prevista']),
      intervaloPrevisto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}intervalo_previsto']),
      retornoPrevisto: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}retorno_previsto']),
      saidaPrevista: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}saida_prevista']),
      ehFolga: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}eh_folga'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $TurnosEscalaTable createAlias(String alias) {
    return $TurnosEscalaTable(attachedDatabase, alias);
  }
}

class TurnoTable extends DataClass implements Insertable<TurnoTable> {
  final String id;
  final String escalaId;
  final String colaboradorId;
  final DateTime data;
  final String? entradaPrevista;
  final String? intervaloPrevisto;
  final String? retornoPrevisto;
  final String? saidaPrevista;
  final bool ehFolga;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncAt;
  const TurnoTable(
      {required this.id,
      required this.escalaId,
      required this.colaboradorId,
      required this.data,
      this.entradaPrevista,
      this.intervaloPrevisto,
      this.retornoPrevisto,
      this.saidaPrevista,
      required this.ehFolga,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['escala_id'] = Variable<String>(escalaId);
    map['colaborador_id'] = Variable<String>(colaboradorId);
    map['data'] = Variable<DateTime>(data);
    if (!nullToAbsent || entradaPrevista != null) {
      map['entrada_prevista'] = Variable<String>(entradaPrevista);
    }
    if (!nullToAbsent || intervaloPrevisto != null) {
      map['intervalo_previsto'] = Variable<String>(intervaloPrevisto);
    }
    if (!nullToAbsent || retornoPrevisto != null) {
      map['retorno_previsto'] = Variable<String>(retornoPrevisto);
    }
    if (!nullToAbsent || saidaPrevista != null) {
      map['saida_prevista'] = Variable<String>(saidaPrevista);
    }
    map['eh_folga'] = Variable<bool>(ehFolga);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  TurnosEscalaCompanion toCompanion(bool nullToAbsent) {
    return TurnosEscalaCompanion(
      id: Value(id),
      escalaId: Value(escalaId),
      colaboradorId: Value(colaboradorId),
      data: Value(data),
      entradaPrevista: entradaPrevista == null && nullToAbsent
          ? const Value.absent()
          : Value(entradaPrevista),
      intervaloPrevisto: intervaloPrevisto == null && nullToAbsent
          ? const Value.absent()
          : Value(intervaloPrevisto),
      retornoPrevisto: retornoPrevisto == null && nullToAbsent
          ? const Value.absent()
          : Value(retornoPrevisto),
      saidaPrevista: saidaPrevista == null && nullToAbsent
          ? const Value.absent()
          : Value(saidaPrevista),
      ehFolga: Value(ehFolga),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory TurnoTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TurnoTable(
      id: serializer.fromJson<String>(json['id']),
      escalaId: serializer.fromJson<String>(json['escalaId']),
      colaboradorId: serializer.fromJson<String>(json['colaboradorId']),
      data: serializer.fromJson<DateTime>(json['data']),
      entradaPrevista: serializer.fromJson<String?>(json['entradaPrevista']),
      intervaloPrevisto:
          serializer.fromJson<String?>(json['intervaloPrevisto']),
      retornoPrevisto: serializer.fromJson<String?>(json['retornoPrevisto']),
      saidaPrevista: serializer.fromJson<String?>(json['saidaPrevista']),
      ehFolga: serializer.fromJson<bool>(json['ehFolga']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'escalaId': serializer.toJson<String>(escalaId),
      'colaboradorId': serializer.toJson<String>(colaboradorId),
      'data': serializer.toJson<DateTime>(data),
      'entradaPrevista': serializer.toJson<String?>(entradaPrevista),
      'intervaloPrevisto': serializer.toJson<String?>(intervaloPrevisto),
      'retornoPrevisto': serializer.toJson<String?>(retornoPrevisto),
      'saidaPrevista': serializer.toJson<String?>(saidaPrevista),
      'ehFolga': serializer.toJson<bool>(ehFolga),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  TurnoTable copyWith(
          {String? id,
          String? escalaId,
          String? colaboradorId,
          DateTime? data,
          Value<String?> entradaPrevista = const Value.absent(),
          Value<String?> intervaloPrevisto = const Value.absent(),
          Value<String?> retornoPrevisto = const Value.absent(),
          Value<String?> saidaPrevista = const Value.absent(),
          bool? ehFolga,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      TurnoTable(
        id: id ?? this.id,
        escalaId: escalaId ?? this.escalaId,
        colaboradorId: colaboradorId ?? this.colaboradorId,
        data: data ?? this.data,
        entradaPrevista: entradaPrevista.present
            ? entradaPrevista.value
            : this.entradaPrevista,
        intervaloPrevisto: intervaloPrevisto.present
            ? intervaloPrevisto.value
            : this.intervaloPrevisto,
        retornoPrevisto: retornoPrevisto.present
            ? retornoPrevisto.value
            : this.retornoPrevisto,
        saidaPrevista:
            saidaPrevista.present ? saidaPrevista.value : this.saidaPrevista,
        ehFolga: ehFolga ?? this.ehFolga,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  TurnoTable copyWithCompanion(TurnosEscalaCompanion data) {
    return TurnoTable(
      id: data.id.present ? data.id.value : this.id,
      escalaId: data.escalaId.present ? data.escalaId.value : this.escalaId,
      colaboradorId: data.colaboradorId.present
          ? data.colaboradorId.value
          : this.colaboradorId,
      data: data.data.present ? data.data.value : this.data,
      entradaPrevista: data.entradaPrevista.present
          ? data.entradaPrevista.value
          : this.entradaPrevista,
      intervaloPrevisto: data.intervaloPrevisto.present
          ? data.intervaloPrevisto.value
          : this.intervaloPrevisto,
      retornoPrevisto: data.retornoPrevisto.present
          ? data.retornoPrevisto.value
          : this.retornoPrevisto,
      saidaPrevista: data.saidaPrevista.present
          ? data.saidaPrevista.value
          : this.saidaPrevista,
      ehFolga: data.ehFolga.present ? data.ehFolga.value : this.ehFolga,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TurnoTable(')
          ..write('id: $id, ')
          ..write('escalaId: $escalaId, ')
          ..write('colaboradorId: $colaboradorId, ')
          ..write('data: $data, ')
          ..write('entradaPrevista: $entradaPrevista, ')
          ..write('intervaloPrevisto: $intervaloPrevisto, ')
          ..write('retornoPrevisto: $retornoPrevisto, ')
          ..write('saidaPrevista: $saidaPrevista, ')
          ..write('ehFolga: $ehFolga, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      escalaId,
      colaboradorId,
      data,
      entradaPrevista,
      intervaloPrevisto,
      retornoPrevisto,
      saidaPrevista,
      ehFolga,
      createdAt,
      updatedAt,
      lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TurnoTable &&
          other.id == this.id &&
          other.escalaId == this.escalaId &&
          other.colaboradorId == this.colaboradorId &&
          other.data == this.data &&
          other.entradaPrevista == this.entradaPrevista &&
          other.intervaloPrevisto == this.intervaloPrevisto &&
          other.retornoPrevisto == this.retornoPrevisto &&
          other.saidaPrevista == this.saidaPrevista &&
          other.ehFolga == this.ehFolga &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class TurnosEscalaCompanion extends UpdateCompanion<TurnoTable> {
  final Value<String> id;
  final Value<String> escalaId;
  final Value<String> colaboradorId;
  final Value<DateTime> data;
  final Value<String?> entradaPrevista;
  final Value<String?> intervaloPrevisto;
  final Value<String?> retornoPrevisto;
  final Value<String?> saidaPrevista;
  final Value<bool> ehFolga;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const TurnosEscalaCompanion({
    this.id = const Value.absent(),
    this.escalaId = const Value.absent(),
    this.colaboradorId = const Value.absent(),
    this.data = const Value.absent(),
    this.entradaPrevista = const Value.absent(),
    this.intervaloPrevisto = const Value.absent(),
    this.retornoPrevisto = const Value.absent(),
    this.saidaPrevista = const Value.absent(),
    this.ehFolga = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TurnosEscalaCompanion.insert({
    required String id,
    required String escalaId,
    required String colaboradorId,
    required DateTime data,
    this.entradaPrevista = const Value.absent(),
    this.intervaloPrevisto = const Value.absent(),
    this.retornoPrevisto = const Value.absent(),
    this.saidaPrevista = const Value.absent(),
    this.ehFolga = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        escalaId = Value(escalaId),
        colaboradorId = Value(colaboradorId),
        data = Value(data);
  static Insertable<TurnoTable> custom({
    Expression<String>? id,
    Expression<String>? escalaId,
    Expression<String>? colaboradorId,
    Expression<DateTime>? data,
    Expression<String>? entradaPrevista,
    Expression<String>? intervaloPrevisto,
    Expression<String>? retornoPrevisto,
    Expression<String>? saidaPrevista,
    Expression<bool>? ehFolga,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (escalaId != null) 'escala_id': escalaId,
      if (colaboradorId != null) 'colaborador_id': colaboradorId,
      if (data != null) 'data': data,
      if (entradaPrevista != null) 'entrada_prevista': entradaPrevista,
      if (intervaloPrevisto != null) 'intervalo_previsto': intervaloPrevisto,
      if (retornoPrevisto != null) 'retorno_previsto': retornoPrevisto,
      if (saidaPrevista != null) 'saida_prevista': saidaPrevista,
      if (ehFolga != null) 'eh_folga': ehFolga,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TurnosEscalaCompanion copyWith(
      {Value<String>? id,
      Value<String>? escalaId,
      Value<String>? colaboradorId,
      Value<DateTime>? data,
      Value<String?>? entradaPrevista,
      Value<String?>? intervaloPrevisto,
      Value<String?>? retornoPrevisto,
      Value<String?>? saidaPrevista,
      Value<bool>? ehFolga,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return TurnosEscalaCompanion(
      id: id ?? this.id,
      escalaId: escalaId ?? this.escalaId,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      data: data ?? this.data,
      entradaPrevista: entradaPrevista ?? this.entradaPrevista,
      intervaloPrevisto: intervaloPrevisto ?? this.intervaloPrevisto,
      retornoPrevisto: retornoPrevisto ?? this.retornoPrevisto,
      saidaPrevista: saidaPrevista ?? this.saidaPrevista,
      ehFolga: ehFolga ?? this.ehFolga,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (escalaId.present) {
      map['escala_id'] = Variable<String>(escalaId.value);
    }
    if (colaboradorId.present) {
      map['colaborador_id'] = Variable<String>(colaboradorId.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (entradaPrevista.present) {
      map['entrada_prevista'] = Variable<String>(entradaPrevista.value);
    }
    if (intervaloPrevisto.present) {
      map['intervalo_previsto'] = Variable<String>(intervaloPrevisto.value);
    }
    if (retornoPrevisto.present) {
      map['retorno_previsto'] = Variable<String>(retornoPrevisto.value);
    }
    if (saidaPrevista.present) {
      map['saida_prevista'] = Variable<String>(saidaPrevista.value);
    }
    if (ehFolga.present) {
      map['eh_folga'] = Variable<bool>(ehFolga.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TurnosEscalaCompanion(')
          ..write('id: $id, ')
          ..write('escalaId: $escalaId, ')
          ..write('colaboradorId: $colaboradorId, ')
          ..write('data: $data, ')
          ..write('entradaPrevista: $entradaPrevista, ')
          ..write('intervaloPrevisto: $intervaloPrevisto, ')
          ..write('retornoPrevisto: $retornoPrevisto, ')
          ..write('saidaPrevista: $saidaPrevista, ')
          ..write('ehFolga: $ehFolga, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlocacoesTable extends Alocacoes
    with TableInfo<$AlocacoesTable, AlocacaoTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlocacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colaboradorIdMeta =
      const VerificationMeta('colaboradorId');
  @override
  late final GeneratedColumn<String> colaboradorId = GeneratedColumn<String>(
      'colaborador_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caixaIdMeta =
      const VerificationMeta('caixaId');
  @override
  late final GeneratedColumn<String> caixaId = GeneratedColumn<String>(
      'caixa_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _turnoEscalaIdMeta =
      const VerificationMeta('turnoEscalaId');
  @override
  late final GeneratedColumn<String> turnoEscalaId = GeneratedColumn<String>(
      'turno_escala_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _alocadoEmMeta =
      const VerificationMeta('alocadoEm');
  @override
  late final GeneratedColumn<DateTime> alocadoEm = GeneratedColumn<DateTime>(
      'alocado_em', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _liberadoEmMeta =
      const VerificationMeta('liberadoEm');
  @override
  late final GeneratedColumn<DateTime> liberadoEm = GeneratedColumn<DateTime>(
      'liberado_em', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _motivoLiberacaoMeta =
      const VerificationMeta('motivoLiberacao');
  @override
  late final GeneratedColumn<String> motivoLiberacao = GeneratedColumn<String>(
      'motivo_liberacao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _alocadoPorMeta =
      const VerificationMeta('alocadoPor');
  @override
  late final GeneratedColumn<String> alocadoPor = GeneratedColumn<String>(
      'alocado_por', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        colaboradorId,
        caixaId,
        turnoEscalaId,
        alocadoEm,
        liberadoEm,
        motivoLiberacao,
        alocadoPor,
        observacoes,
        createdAt,
        lastSyncAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alocacoes';
  @override
  VerificationContext validateIntegrity(Insertable<AlocacaoTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('colaborador_id')) {
      context.handle(
          _colaboradorIdMeta,
          colaboradorId.isAcceptableOrUnknown(
              data['colaborador_id']!, _colaboradorIdMeta));
    } else if (isInserting) {
      context.missing(_colaboradorIdMeta);
    }
    if (data.containsKey('caixa_id')) {
      context.handle(_caixaIdMeta,
          caixaId.isAcceptableOrUnknown(data['caixa_id']!, _caixaIdMeta));
    } else if (isInserting) {
      context.missing(_caixaIdMeta);
    }
    if (data.containsKey('turno_escala_id')) {
      context.handle(
          _turnoEscalaIdMeta,
          turnoEscalaId.isAcceptableOrUnknown(
              data['turno_escala_id']!, _turnoEscalaIdMeta));
    }
    if (data.containsKey('alocado_em')) {
      context.handle(_alocadoEmMeta,
          alocadoEm.isAcceptableOrUnknown(data['alocado_em']!, _alocadoEmMeta));
    } else if (isInserting) {
      context.missing(_alocadoEmMeta);
    }
    if (data.containsKey('liberado_em')) {
      context.handle(
          _liberadoEmMeta,
          liberadoEm.isAcceptableOrUnknown(
              data['liberado_em']!, _liberadoEmMeta));
    }
    if (data.containsKey('motivo_liberacao')) {
      context.handle(
          _motivoLiberacaoMeta,
          motivoLiberacao.isAcceptableOrUnknown(
              data['motivo_liberacao']!, _motivoLiberacaoMeta));
    }
    if (data.containsKey('alocado_por')) {
      context.handle(
          _alocadoPorMeta,
          alocadoPor.isAcceptableOrUnknown(
              data['alocado_por']!, _alocadoPorMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlocacaoTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlocacaoTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      colaboradorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}colaborador_id'])!,
      caixaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caixa_id'])!,
      turnoEscalaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}turno_escala_id']),
      alocadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}alocado_em'])!,
      liberadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}liberado_em']),
      motivoLiberacao: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}motivo_liberacao']),
      alocadoPor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alocado_por']),
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $AlocacoesTable createAlias(String alias) {
    return $AlocacoesTable(attachedDatabase, alias);
  }
}

class AlocacaoTable extends DataClass implements Insertable<AlocacaoTable> {
  final String id;
  final String colaboradorId;
  final String caixaId;
  final String? turnoEscalaId;
  final DateTime alocadoEm;
  final DateTime? liberadoEm;
  final String? motivoLiberacao;
  final String? alocadoPor;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  const AlocacaoTable(
      {required this.id,
      required this.colaboradorId,
      required this.caixaId,
      this.turnoEscalaId,
      required this.alocadoEm,
      this.liberadoEm,
      this.motivoLiberacao,
      this.alocadoPor,
      this.observacoes,
      required this.createdAt,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['colaborador_id'] = Variable<String>(colaboradorId);
    map['caixa_id'] = Variable<String>(caixaId);
    if (!nullToAbsent || turnoEscalaId != null) {
      map['turno_escala_id'] = Variable<String>(turnoEscalaId);
    }
    map['alocado_em'] = Variable<DateTime>(alocadoEm);
    if (!nullToAbsent || liberadoEm != null) {
      map['liberado_em'] = Variable<DateTime>(liberadoEm);
    }
    if (!nullToAbsent || motivoLiberacao != null) {
      map['motivo_liberacao'] = Variable<String>(motivoLiberacao);
    }
    if (!nullToAbsent || alocadoPor != null) {
      map['alocado_por'] = Variable<String>(alocadoPor);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  AlocacoesCompanion toCompanion(bool nullToAbsent) {
    return AlocacoesCompanion(
      id: Value(id),
      colaboradorId: Value(colaboradorId),
      caixaId: Value(caixaId),
      turnoEscalaId: turnoEscalaId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnoEscalaId),
      alocadoEm: Value(alocadoEm),
      liberadoEm: liberadoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(liberadoEm),
      motivoLiberacao: motivoLiberacao == null && nullToAbsent
          ? const Value.absent()
          : Value(motivoLiberacao),
      alocadoPor: alocadoPor == null && nullToAbsent
          ? const Value.absent()
          : Value(alocadoPor),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
      createdAt: Value(createdAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory AlocacaoTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlocacaoTable(
      id: serializer.fromJson<String>(json['id']),
      colaboradorId: serializer.fromJson<String>(json['colaboradorId']),
      caixaId: serializer.fromJson<String>(json['caixaId']),
      turnoEscalaId: serializer.fromJson<String?>(json['turnoEscalaId']),
      alocadoEm: serializer.fromJson<DateTime>(json['alocadoEm']),
      liberadoEm: serializer.fromJson<DateTime?>(json['liberadoEm']),
      motivoLiberacao: serializer.fromJson<String?>(json['motivoLiberacao']),
      alocadoPor: serializer.fromJson<String?>(json['alocadoPor']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'colaboradorId': serializer.toJson<String>(colaboradorId),
      'caixaId': serializer.toJson<String>(caixaId),
      'turnoEscalaId': serializer.toJson<String?>(turnoEscalaId),
      'alocadoEm': serializer.toJson<DateTime>(alocadoEm),
      'liberadoEm': serializer.toJson<DateTime?>(liberadoEm),
      'motivoLiberacao': serializer.toJson<String?>(motivoLiberacao),
      'alocadoPor': serializer.toJson<String?>(alocadoPor),
      'observacoes': serializer.toJson<String?>(observacoes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  AlocacaoTable copyWith(
          {String? id,
          String? colaboradorId,
          String? caixaId,
          Value<String?> turnoEscalaId = const Value.absent(),
          DateTime? alocadoEm,
          Value<DateTime?> liberadoEm = const Value.absent(),
          Value<String?> motivoLiberacao = const Value.absent(),
          Value<String?> alocadoPor = const Value.absent(),
          Value<String?> observacoes = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      AlocacaoTable(
        id: id ?? this.id,
        colaboradorId: colaboradorId ?? this.colaboradorId,
        caixaId: caixaId ?? this.caixaId,
        turnoEscalaId:
            turnoEscalaId.present ? turnoEscalaId.value : this.turnoEscalaId,
        alocadoEm: alocadoEm ?? this.alocadoEm,
        liberadoEm: liberadoEm.present ? liberadoEm.value : this.liberadoEm,
        motivoLiberacao: motivoLiberacao.present
            ? motivoLiberacao.value
            : this.motivoLiberacao,
        alocadoPor: alocadoPor.present ? alocadoPor.value : this.alocadoPor,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
        createdAt: createdAt ?? this.createdAt,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  AlocacaoTable copyWithCompanion(AlocacoesCompanion data) {
    return AlocacaoTable(
      id: data.id.present ? data.id.value : this.id,
      colaboradorId: data.colaboradorId.present
          ? data.colaboradorId.value
          : this.colaboradorId,
      caixaId: data.caixaId.present ? data.caixaId.value : this.caixaId,
      turnoEscalaId: data.turnoEscalaId.present
          ? data.turnoEscalaId.value
          : this.turnoEscalaId,
      alocadoEm: data.alocadoEm.present ? data.alocadoEm.value : this.alocadoEm,
      liberadoEm:
          data.liberadoEm.present ? data.liberadoEm.value : this.liberadoEm,
      motivoLiberacao: data.motivoLiberacao.present
          ? data.motivoLiberacao.value
          : this.motivoLiberacao,
      alocadoPor:
          data.alocadoPor.present ? data.alocadoPor.value : this.alocadoPor,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlocacaoTable(')
          ..write('id: $id, ')
          ..write('colaboradorId: $colaboradorId, ')
          ..write('caixaId: $caixaId, ')
          ..write('turnoEscalaId: $turnoEscalaId, ')
          ..write('alocadoEm: $alocadoEm, ')
          ..write('liberadoEm: $liberadoEm, ')
          ..write('motivoLiberacao: $motivoLiberacao, ')
          ..write('alocadoPor: $alocadoPor, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      colaboradorId,
      caixaId,
      turnoEscalaId,
      alocadoEm,
      liberadoEm,
      motivoLiberacao,
      alocadoPor,
      observacoes,
      createdAt,
      lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlocacaoTable &&
          other.id == this.id &&
          other.colaboradorId == this.colaboradorId &&
          other.caixaId == this.caixaId &&
          other.turnoEscalaId == this.turnoEscalaId &&
          other.alocadoEm == this.alocadoEm &&
          other.liberadoEm == this.liberadoEm &&
          other.motivoLiberacao == this.motivoLiberacao &&
          other.alocadoPor == this.alocadoPor &&
          other.observacoes == this.observacoes &&
          other.createdAt == this.createdAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class AlocacoesCompanion extends UpdateCompanion<AlocacaoTable> {
  final Value<String> id;
  final Value<String> colaboradorId;
  final Value<String> caixaId;
  final Value<String?> turnoEscalaId;
  final Value<DateTime> alocadoEm;
  final Value<DateTime?> liberadoEm;
  final Value<String?> motivoLiberacao;
  final Value<String?> alocadoPor;
  final Value<String?> observacoes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const AlocacoesCompanion({
    this.id = const Value.absent(),
    this.colaboradorId = const Value.absent(),
    this.caixaId = const Value.absent(),
    this.turnoEscalaId = const Value.absent(),
    this.alocadoEm = const Value.absent(),
    this.liberadoEm = const Value.absent(),
    this.motivoLiberacao = const Value.absent(),
    this.alocadoPor = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlocacoesCompanion.insert({
    required String id,
    required String colaboradorId,
    required String caixaId,
    this.turnoEscalaId = const Value.absent(),
    required DateTime alocadoEm,
    this.liberadoEm = const Value.absent(),
    this.motivoLiberacao = const Value.absent(),
    this.alocadoPor = const Value.absent(),
    this.observacoes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        colaboradorId = Value(colaboradorId),
        caixaId = Value(caixaId),
        alocadoEm = Value(alocadoEm);
  static Insertable<AlocacaoTable> custom({
    Expression<String>? id,
    Expression<String>? colaboradorId,
    Expression<String>? caixaId,
    Expression<String>? turnoEscalaId,
    Expression<DateTime>? alocadoEm,
    Expression<DateTime>? liberadoEm,
    Expression<String>? motivoLiberacao,
    Expression<String>? alocadoPor,
    Expression<String>? observacoes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (colaboradorId != null) 'colaborador_id': colaboradorId,
      if (caixaId != null) 'caixa_id': caixaId,
      if (turnoEscalaId != null) 'turno_escala_id': turnoEscalaId,
      if (alocadoEm != null) 'alocado_em': alocadoEm,
      if (liberadoEm != null) 'liberado_em': liberadoEm,
      if (motivoLiberacao != null) 'motivo_liberacao': motivoLiberacao,
      if (alocadoPor != null) 'alocado_por': alocadoPor,
      if (observacoes != null) 'observacoes': observacoes,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlocacoesCompanion copyWith(
      {Value<String>? id,
      Value<String>? colaboradorId,
      Value<String>? caixaId,
      Value<String?>? turnoEscalaId,
      Value<DateTime>? alocadoEm,
      Value<DateTime?>? liberadoEm,
      Value<String?>? motivoLiberacao,
      Value<String?>? alocadoPor,
      Value<String?>? observacoes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return AlocacoesCompanion(
      id: id ?? this.id,
      colaboradorId: colaboradorId ?? this.colaboradorId,
      caixaId: caixaId ?? this.caixaId,
      turnoEscalaId: turnoEscalaId ?? this.turnoEscalaId,
      alocadoEm: alocadoEm ?? this.alocadoEm,
      liberadoEm: liberadoEm ?? this.liberadoEm,
      motivoLiberacao: motivoLiberacao ?? this.motivoLiberacao,
      alocadoPor: alocadoPor ?? this.alocadoPor,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (colaboradorId.present) {
      map['colaborador_id'] = Variable<String>(colaboradorId.value);
    }
    if (caixaId.present) {
      map['caixa_id'] = Variable<String>(caixaId.value);
    }
    if (turnoEscalaId.present) {
      map['turno_escala_id'] = Variable<String>(turnoEscalaId.value);
    }
    if (alocadoEm.present) {
      map['alocado_em'] = Variable<DateTime>(alocadoEm.value);
    }
    if (liberadoEm.present) {
      map['liberado_em'] = Variable<DateTime>(liberadoEm.value);
    }
    if (motivoLiberacao.present) {
      map['motivo_liberacao'] = Variable<String>(motivoLiberacao.value);
    }
    if (alocadoPor.present) {
      map['alocado_por'] = Variable<String>(alocadoPor.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlocacoesCompanion(')
          ..write('id: $id, ')
          ..write('colaboradorId: $colaboradorId, ')
          ..write('caixaId: $caixaId, ')
          ..write('turnoEscalaId: $turnoEscalaId, ')
          ..write('alocadoEm: $alocadoEm, ')
          ..write('liberadoEm: $liberadoEm, ')
          ..write('motivoLiberacao: $motivoLiberacao, ')
          ..write('alocadoPor: $alocadoPor, ')
          ..write('observacoes: $observacoes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FiscaisTable fiscais = $FiscaisTable(this);
  late final $ColaboradoresTable colaboradores = $ColaboradoresTable(this);
  late final $CaixasTable caixas = $CaixasTable(this);
  late final $TurnosEscalaTable turnosEscala = $TurnosEscalaTable(this);
  late final $AlocacoesTable alocacoes = $AlocacoesTable(this);
  late final FiscalDao fiscalDao = FiscalDao(this as AppDatabase);
  late final ColaboradorDao colaboradorDao =
      ColaboradorDao(this as AppDatabase);
  late final CaixaDao caixaDao = CaixaDao(this as AppDatabase);
  late final AlocacaoDao alocacaoDao = AlocacaoDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [fiscais, colaboradores, caixas, turnosEscala, alocacoes];
}

typedef $$FiscaisTableCreateCompanionBuilder = FiscaisCompanion Function({
  required String id,
  required String userId,
  required String nome,
  Value<String?> cpf,
  Value<String?> telefone,
  Value<String> lojaNome,
  Value<String> lojaHorarioAbertura,
  Value<String> lojaHorarioFechamento,
  Value<String> lojaHorarioDomingoAbertura,
  Value<String> lojaHorarioDomingoFechamento,
  Value<String?> preferencias,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$FiscaisTableUpdateCompanionBuilder = FiscaisCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> nome,
  Value<String?> cpf,
  Value<String?> telefone,
  Value<String> lojaNome,
  Value<String> lojaHorarioAbertura,
  Value<String> lojaHorarioFechamento,
  Value<String> lojaHorarioDomingoAbertura,
  Value<String> lojaHorarioDomingoFechamento,
  Value<String?> preferencias,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$FiscaisTableFilterComposer
    extends Composer<_$AppDatabase, $FiscaisTable> {
  $$FiscaisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cpf => $composableBuilder(
      column: $table.cpf, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lojaNome => $composableBuilder(
      column: $table.lojaNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lojaHorarioAbertura => $composableBuilder(
      column: $table.lojaHorarioAbertura,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lojaHorarioFechamento => $composableBuilder(
      column: $table.lojaHorarioFechamento,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lojaHorarioDomingoAbertura => $composableBuilder(
      column: $table.lojaHorarioDomingoAbertura,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lojaHorarioDomingoFechamento => $composableBuilder(
      column: $table.lojaHorarioDomingoFechamento,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preferencias => $composableBuilder(
      column: $table.preferencias, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$FiscaisTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscaisTable> {
  $$FiscaisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cpf => $composableBuilder(
      column: $table.cpf, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get telefone => $composableBuilder(
      column: $table.telefone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lojaNome => $composableBuilder(
      column: $table.lojaNome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lojaHorarioAbertura => $composableBuilder(
      column: $table.lojaHorarioAbertura,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lojaHorarioFechamento => $composableBuilder(
      column: $table.lojaHorarioFechamento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lojaHorarioDomingoAbertura => $composableBuilder(
      column: $table.lojaHorarioDomingoAbertura,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lojaHorarioDomingoFechamento =>
      $composableBuilder(
          column: $table.lojaHorarioDomingoFechamento,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preferencias => $composableBuilder(
      column: $table.preferencias,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$FiscaisTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscaisTable> {
  $$FiscaisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get cpf =>
      $composableBuilder(column: $table.cpf, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get lojaNome =>
      $composableBuilder(column: $table.lojaNome, builder: (column) => column);

  GeneratedColumn<String> get lojaHorarioAbertura => $composableBuilder(
      column: $table.lojaHorarioAbertura, builder: (column) => column);

  GeneratedColumn<String> get lojaHorarioFechamento => $composableBuilder(
      column: $table.lojaHorarioFechamento, builder: (column) => column);

  GeneratedColumn<String> get lojaHorarioDomingoAbertura => $composableBuilder(
      column: $table.lojaHorarioDomingoAbertura, builder: (column) => column);

  GeneratedColumn<String> get lojaHorarioDomingoFechamento =>
      $composableBuilder(
          column: $table.lojaHorarioDomingoFechamento,
          builder: (column) => column);

  GeneratedColumn<String> get preferencias => $composableBuilder(
      column: $table.preferencias, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$FiscaisTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FiscaisTable,
    FiscalTable,
    $$FiscaisTableFilterComposer,
    $$FiscaisTableOrderingComposer,
    $$FiscaisTableAnnotationComposer,
    $$FiscaisTableCreateCompanionBuilder,
    $$FiscaisTableUpdateCompanionBuilder,
    (FiscalTable, BaseReferences<_$AppDatabase, $FiscaisTable, FiscalTable>),
    FiscalTable,
    PrefetchHooks Function()> {
  $$FiscaisTableTableManager(_$AppDatabase db, $FiscaisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscaisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscaisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscaisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> cpf = const Value.absent(),
            Value<String?> telefone = const Value.absent(),
            Value<String> lojaNome = const Value.absent(),
            Value<String> lojaHorarioAbertura = const Value.absent(),
            Value<String> lojaHorarioFechamento = const Value.absent(),
            Value<String> lojaHorarioDomingoAbertura = const Value.absent(),
            Value<String> lojaHorarioDomingoFechamento = const Value.absent(),
            Value<String?> preferencias = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FiscaisCompanion(
            id: id,
            userId: userId,
            nome: nome,
            cpf: cpf,
            telefone: telefone,
            lojaNome: lojaNome,
            lojaHorarioAbertura: lojaHorarioAbertura,
            lojaHorarioFechamento: lojaHorarioFechamento,
            lojaHorarioDomingoAbertura: lojaHorarioDomingoAbertura,
            lojaHorarioDomingoFechamento: lojaHorarioDomingoFechamento,
            preferencias: preferencias,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String nome,
            Value<String?> cpf = const Value.absent(),
            Value<String?> telefone = const Value.absent(),
            Value<String> lojaNome = const Value.absent(),
            Value<String> lojaHorarioAbertura = const Value.absent(),
            Value<String> lojaHorarioFechamento = const Value.absent(),
            Value<String> lojaHorarioDomingoAbertura = const Value.absent(),
            Value<String> lojaHorarioDomingoFechamento = const Value.absent(),
            Value<String?> preferencias = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FiscaisCompanion.insert(
            id: id,
            userId: userId,
            nome: nome,
            cpf: cpf,
            telefone: telefone,
            lojaNome: lojaNome,
            lojaHorarioAbertura: lojaHorarioAbertura,
            lojaHorarioFechamento: lojaHorarioFechamento,
            lojaHorarioDomingoAbertura: lojaHorarioDomingoAbertura,
            lojaHorarioDomingoFechamento: lojaHorarioDomingoFechamento,
            preferencias: preferencias,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FiscaisTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FiscaisTable,
    FiscalTable,
    $$FiscaisTableFilterComposer,
    $$FiscaisTableOrderingComposer,
    $$FiscaisTableAnnotationComposer,
    $$FiscaisTableCreateCompanionBuilder,
    $$FiscaisTableUpdateCompanionBuilder,
    (FiscalTable, BaseReferences<_$AppDatabase, $FiscaisTable, FiscalTable>),
    FiscalTable,
    PrefetchHooks Function()>;
typedef $$ColaboradoresTableCreateCompanionBuilder = ColaboradoresCompanion
    Function({
  required String id,
  required String fiscalId,
  required String nome,
  required String departamento,
  Value<String?> avatarIniciais,
  Value<bool> ativo,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$ColaboradoresTableUpdateCompanionBuilder = ColaboradoresCompanion
    Function({
  Value<String> id,
  Value<String> fiscalId,
  Value<String> nome,
  Value<String> departamento,
  Value<String?> avatarIniciais,
  Value<bool> ativo,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$ColaboradoresTableFilterComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fiscalId => $composableBuilder(
      column: $table.fiscalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarIniciais => $composableBuilder(
      column: $table.avatarIniciais,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$ColaboradoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fiscalId => $composableBuilder(
      column: $table.fiscalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get departamento => $composableBuilder(
      column: $table.departamento,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarIniciais => $composableBuilder(
      column: $table.avatarIniciais,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$ColaboradoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ColaboradoresTable> {
  $$ColaboradoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fiscalId =>
      $composableBuilder(column: $table.fiscalId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get departamento => $composableBuilder(
      column: $table.departamento, builder: (column) => column);

  GeneratedColumn<String> get avatarIniciais => $composableBuilder(
      column: $table.avatarIniciais, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$ColaboradoresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ColaboradoresTable,
    ColaboradorTable,
    $$ColaboradoresTableFilterComposer,
    $$ColaboradoresTableOrderingComposer,
    $$ColaboradoresTableAnnotationComposer,
    $$ColaboradoresTableCreateCompanionBuilder,
    $$ColaboradoresTableUpdateCompanionBuilder,
    (
      ColaboradorTable,
      BaseReferences<_$AppDatabase, $ColaboradoresTable, ColaboradorTable>
    ),
    ColaboradorTable,
    PrefetchHooks Function()> {
  $$ColaboradoresTableTableManager(_$AppDatabase db, $ColaboradoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColaboradoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColaboradoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColaboradoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fiscalId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> departamento = const Value.absent(),
            Value<String?> avatarIniciais = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ColaboradoresCompanion(
            id: id,
            fiscalId: fiscalId,
            nome: nome,
            departamento: departamento,
            avatarIniciais: avatarIniciais,
            ativo: ativo,
            observacoes: observacoes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fiscalId,
            required String nome,
            required String departamento,
            Value<String?> avatarIniciais = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ColaboradoresCompanion.insert(
            id: id,
            fiscalId: fiscalId,
            nome: nome,
            departamento: departamento,
            avatarIniciais: avatarIniciais,
            ativo: ativo,
            observacoes: observacoes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ColaboradoresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ColaboradoresTable,
    ColaboradorTable,
    $$ColaboradoresTableFilterComposer,
    $$ColaboradoresTableOrderingComposer,
    $$ColaboradoresTableAnnotationComposer,
    $$ColaboradoresTableCreateCompanionBuilder,
    $$ColaboradoresTableUpdateCompanionBuilder,
    (
      ColaboradorTable,
      BaseReferences<_$AppDatabase, $ColaboradoresTable, ColaboradorTable>
    ),
    ColaboradorTable,
    PrefetchHooks Function()>;
typedef $$CaixasTableCreateCompanionBuilder = CaixasCompanion Function({
  required String id,
  required String fiscalId,
  required int numero,
  required String tipo,
  Value<bool> ativo,
  Value<bool> emManutencao,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$CaixasTableUpdateCompanionBuilder = CaixasCompanion Function({
  Value<String> id,
  Value<String> fiscalId,
  Value<int> numero,
  Value<String> tipo,
  Value<bool> ativo,
  Value<bool> emManutencao,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$CaixasTableFilterComposer
    extends Composer<_$AppDatabase, $CaixasTable> {
  $$CaixasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fiscalId => $composableBuilder(
      column: $table.fiscalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get emManutencao => $composableBuilder(
      column: $table.emManutencao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$CaixasTableOrderingComposer
    extends Composer<_$AppDatabase, $CaixasTable> {
  $$CaixasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fiscalId => $composableBuilder(
      column: $table.fiscalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numero => $composableBuilder(
      column: $table.numero, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get emManutencao => $composableBuilder(
      column: $table.emManutencao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$CaixasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CaixasTable> {
  $$CaixasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fiscalId =>
      $composableBuilder(column: $table.fiscalId, builder: (column) => column);

  GeneratedColumn<int> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  GeneratedColumn<bool> get emManutencao => $composableBuilder(
      column: $table.emManutencao, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$CaixasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CaixasTable,
    CaixaTable,
    $$CaixasTableFilterComposer,
    $$CaixasTableOrderingComposer,
    $$CaixasTableAnnotationComposer,
    $$CaixasTableCreateCompanionBuilder,
    $$CaixasTableUpdateCompanionBuilder,
    (CaixaTable, BaseReferences<_$AppDatabase, $CaixasTable, CaixaTable>),
    CaixaTable,
    PrefetchHooks Function()> {
  $$CaixasTableTableManager(_$AppDatabase db, $CaixasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaixasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaixasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaixasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fiscalId = const Value.absent(),
            Value<int> numero = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
            Value<bool> emManutencao = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CaixasCompanion(
            id: id,
            fiscalId: fiscalId,
            numero: numero,
            tipo: tipo,
            ativo: ativo,
            emManutencao: emManutencao,
            observacoes: observacoes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fiscalId,
            required int numero,
            required String tipo,
            Value<bool> ativo = const Value.absent(),
            Value<bool> emManutencao = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CaixasCompanion.insert(
            id: id,
            fiscalId: fiscalId,
            numero: numero,
            tipo: tipo,
            ativo: ativo,
            emManutencao: emManutencao,
            observacoes: observacoes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CaixasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CaixasTable,
    CaixaTable,
    $$CaixasTableFilterComposer,
    $$CaixasTableOrderingComposer,
    $$CaixasTableAnnotationComposer,
    $$CaixasTableCreateCompanionBuilder,
    $$CaixasTableUpdateCompanionBuilder,
    (CaixaTable, BaseReferences<_$AppDatabase, $CaixasTable, CaixaTable>),
    CaixaTable,
    PrefetchHooks Function()>;
typedef $$TurnosEscalaTableCreateCompanionBuilder = TurnosEscalaCompanion
    Function({
  required String id,
  required String escalaId,
  required String colaboradorId,
  required DateTime data,
  Value<String?> entradaPrevista,
  Value<String?> intervaloPrevisto,
  Value<String?> retornoPrevisto,
  Value<String?> saidaPrevista,
  Value<bool> ehFolga,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$TurnosEscalaTableUpdateCompanionBuilder = TurnosEscalaCompanion
    Function({
  Value<String> id,
  Value<String> escalaId,
  Value<String> colaboradorId,
  Value<DateTime> data,
  Value<String?> entradaPrevista,
  Value<String?> intervaloPrevisto,
  Value<String?> retornoPrevisto,
  Value<String?> saidaPrevista,
  Value<bool> ehFolga,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$TurnosEscalaTableFilterComposer
    extends Composer<_$AppDatabase, $TurnosEscalaTable> {
  $$TurnosEscalaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get escalaId => $composableBuilder(
      column: $table.escalaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entradaPrevista => $composableBuilder(
      column: $table.entradaPrevista,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intervaloPrevisto => $composableBuilder(
      column: $table.intervaloPrevisto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get retornoPrevisto => $composableBuilder(
      column: $table.retornoPrevisto,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saidaPrevista => $composableBuilder(
      column: $table.saidaPrevista, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ehFolga => $composableBuilder(
      column: $table.ehFolga, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$TurnosEscalaTableOrderingComposer
    extends Composer<_$AppDatabase, $TurnosEscalaTable> {
  $$TurnosEscalaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get escalaId => $composableBuilder(
      column: $table.escalaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entradaPrevista => $composableBuilder(
      column: $table.entradaPrevista,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intervaloPrevisto => $composableBuilder(
      column: $table.intervaloPrevisto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get retornoPrevisto => $composableBuilder(
      column: $table.retornoPrevisto,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saidaPrevista => $composableBuilder(
      column: $table.saidaPrevista,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ehFolga => $composableBuilder(
      column: $table.ehFolga, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$TurnosEscalaTableAnnotationComposer
    extends Composer<_$AppDatabase, $TurnosEscalaTable> {
  $$TurnosEscalaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get escalaId =>
      $composableBuilder(column: $table.escalaId, builder: (column) => column);

  GeneratedColumn<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get entradaPrevista => $composableBuilder(
      column: $table.entradaPrevista, builder: (column) => column);

  GeneratedColumn<String> get intervaloPrevisto => $composableBuilder(
      column: $table.intervaloPrevisto, builder: (column) => column);

  GeneratedColumn<String> get retornoPrevisto => $composableBuilder(
      column: $table.retornoPrevisto, builder: (column) => column);

  GeneratedColumn<String> get saidaPrevista => $composableBuilder(
      column: $table.saidaPrevista, builder: (column) => column);

  GeneratedColumn<bool> get ehFolga =>
      $composableBuilder(column: $table.ehFolga, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$TurnosEscalaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TurnosEscalaTable,
    TurnoTable,
    $$TurnosEscalaTableFilterComposer,
    $$TurnosEscalaTableOrderingComposer,
    $$TurnosEscalaTableAnnotationComposer,
    $$TurnosEscalaTableCreateCompanionBuilder,
    $$TurnosEscalaTableUpdateCompanionBuilder,
    (TurnoTable, BaseReferences<_$AppDatabase, $TurnosEscalaTable, TurnoTable>),
    TurnoTable,
    PrefetchHooks Function()> {
  $$TurnosEscalaTableTableManager(_$AppDatabase db, $TurnosEscalaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TurnosEscalaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TurnosEscalaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TurnosEscalaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> escalaId = const Value.absent(),
            Value<String> colaboradorId = const Value.absent(),
            Value<DateTime> data = const Value.absent(),
            Value<String?> entradaPrevista = const Value.absent(),
            Value<String?> intervaloPrevisto = const Value.absent(),
            Value<String?> retornoPrevisto = const Value.absent(),
            Value<String?> saidaPrevista = const Value.absent(),
            Value<bool> ehFolga = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TurnosEscalaCompanion(
            id: id,
            escalaId: escalaId,
            colaboradorId: colaboradorId,
            data: data,
            entradaPrevista: entradaPrevista,
            intervaloPrevisto: intervaloPrevisto,
            retornoPrevisto: retornoPrevisto,
            saidaPrevista: saidaPrevista,
            ehFolga: ehFolga,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String escalaId,
            required String colaboradorId,
            required DateTime data,
            Value<String?> entradaPrevista = const Value.absent(),
            Value<String?> intervaloPrevisto = const Value.absent(),
            Value<String?> retornoPrevisto = const Value.absent(),
            Value<String?> saidaPrevista = const Value.absent(),
            Value<bool> ehFolga = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TurnosEscalaCompanion.insert(
            id: id,
            escalaId: escalaId,
            colaboradorId: colaboradorId,
            data: data,
            entradaPrevista: entradaPrevista,
            intervaloPrevisto: intervaloPrevisto,
            retornoPrevisto: retornoPrevisto,
            saidaPrevista: saidaPrevista,
            ehFolga: ehFolga,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TurnosEscalaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TurnosEscalaTable,
    TurnoTable,
    $$TurnosEscalaTableFilterComposer,
    $$TurnosEscalaTableOrderingComposer,
    $$TurnosEscalaTableAnnotationComposer,
    $$TurnosEscalaTableCreateCompanionBuilder,
    $$TurnosEscalaTableUpdateCompanionBuilder,
    (TurnoTable, BaseReferences<_$AppDatabase, $TurnosEscalaTable, TurnoTable>),
    TurnoTable,
    PrefetchHooks Function()>;
typedef $$AlocacoesTableCreateCompanionBuilder = AlocacoesCompanion Function({
  required String id,
  required String colaboradorId,
  required String caixaId,
  Value<String?> turnoEscalaId,
  required DateTime alocadoEm,
  Value<DateTime?> liberadoEm,
  Value<String?> motivoLiberacao,
  Value<String?> alocadoPor,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$AlocacoesTableUpdateCompanionBuilder = AlocacoesCompanion Function({
  Value<String> id,
  Value<String> colaboradorId,
  Value<String> caixaId,
  Value<String?> turnoEscalaId,
  Value<DateTime> alocadoEm,
  Value<DateTime?> liberadoEm,
  Value<String?> motivoLiberacao,
  Value<String?> alocadoPor,
  Value<String?> observacoes,
  Value<DateTime> createdAt,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$AlocacoesTableFilterComposer
    extends Composer<_$AppDatabase, $AlocacoesTable> {
  $$AlocacoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caixaId => $composableBuilder(
      column: $table.caixaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get turnoEscalaId => $composableBuilder(
      column: $table.turnoEscalaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get alocadoEm => $composableBuilder(
      column: $table.alocadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get liberadoEm => $composableBuilder(
      column: $table.liberadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivoLiberacao => $composableBuilder(
      column: $table.motivoLiberacao,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alocadoPor => $composableBuilder(
      column: $table.alocadoPor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$AlocacoesTableOrderingComposer
    extends Composer<_$AppDatabase, $AlocacoesTable> {
  $$AlocacoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caixaId => $composableBuilder(
      column: $table.caixaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get turnoEscalaId => $composableBuilder(
      column: $table.turnoEscalaId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get alocadoEm => $composableBuilder(
      column: $table.alocadoEm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get liberadoEm => $composableBuilder(
      column: $table.liberadoEm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivoLiberacao => $composableBuilder(
      column: $table.motivoLiberacao,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alocadoPor => $composableBuilder(
      column: $table.alocadoPor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$AlocacoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlocacoesTable> {
  $$AlocacoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get colaboradorId => $composableBuilder(
      column: $table.colaboradorId, builder: (column) => column);

  GeneratedColumn<String> get caixaId =>
      $composableBuilder(column: $table.caixaId, builder: (column) => column);

  GeneratedColumn<String> get turnoEscalaId => $composableBuilder(
      column: $table.turnoEscalaId, builder: (column) => column);

  GeneratedColumn<DateTime> get alocadoEm =>
      $composableBuilder(column: $table.alocadoEm, builder: (column) => column);

  GeneratedColumn<DateTime> get liberadoEm => $composableBuilder(
      column: $table.liberadoEm, builder: (column) => column);

  GeneratedColumn<String> get motivoLiberacao => $composableBuilder(
      column: $table.motivoLiberacao, builder: (column) => column);

  GeneratedColumn<String> get alocadoPor => $composableBuilder(
      column: $table.alocadoPor, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$AlocacoesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlocacoesTable,
    AlocacaoTable,
    $$AlocacoesTableFilterComposer,
    $$AlocacoesTableOrderingComposer,
    $$AlocacoesTableAnnotationComposer,
    $$AlocacoesTableCreateCompanionBuilder,
    $$AlocacoesTableUpdateCompanionBuilder,
    (
      AlocacaoTable,
      BaseReferences<_$AppDatabase, $AlocacoesTable, AlocacaoTable>
    ),
    AlocacaoTable,
    PrefetchHooks Function()> {
  $$AlocacoesTableTableManager(_$AppDatabase db, $AlocacoesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlocacoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlocacoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlocacoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> colaboradorId = const Value.absent(),
            Value<String> caixaId = const Value.absent(),
            Value<String?> turnoEscalaId = const Value.absent(),
            Value<DateTime> alocadoEm = const Value.absent(),
            Value<DateTime?> liberadoEm = const Value.absent(),
            Value<String?> motivoLiberacao = const Value.absent(),
            Value<String?> alocadoPor = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlocacoesCompanion(
            id: id,
            colaboradorId: colaboradorId,
            caixaId: caixaId,
            turnoEscalaId: turnoEscalaId,
            alocadoEm: alocadoEm,
            liberadoEm: liberadoEm,
            motivoLiberacao: motivoLiberacao,
            alocadoPor: alocadoPor,
            observacoes: observacoes,
            createdAt: createdAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String colaboradorId,
            required String caixaId,
            Value<String?> turnoEscalaId = const Value.absent(),
            required DateTime alocadoEm,
            Value<DateTime?> liberadoEm = const Value.absent(),
            Value<String?> motivoLiberacao = const Value.absent(),
            Value<String?> alocadoPor = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlocacoesCompanion.insert(
            id: id,
            colaboradorId: colaboradorId,
            caixaId: caixaId,
            turnoEscalaId: turnoEscalaId,
            alocadoEm: alocadoEm,
            liberadoEm: liberadoEm,
            motivoLiberacao: motivoLiberacao,
            alocadoPor: alocadoPor,
            observacoes: observacoes,
            createdAt: createdAt,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AlocacoesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlocacoesTable,
    AlocacaoTable,
    $$AlocacoesTableFilterComposer,
    $$AlocacoesTableOrderingComposer,
    $$AlocacoesTableAnnotationComposer,
    $$AlocacoesTableCreateCompanionBuilder,
    $$AlocacoesTableUpdateCompanionBuilder,
    (
      AlocacaoTable,
      BaseReferences<_$AppDatabase, $AlocacoesTable, AlocacaoTable>
    ),
    AlocacaoTable,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FiscaisTableTableManager get fiscais =>
      $$FiscaisTableTableManager(_db, _db.fiscais);
  $$ColaboradoresTableTableManager get colaboradores =>
      $$ColaboradoresTableTableManager(_db, _db.colaboradores);
  $$CaixasTableTableManager get caixas =>
      $$CaixasTableTableManager(_db, _db.caixas);
  $$TurnosEscalaTableTableManager get turnosEscala =>
      $$TurnosEscalaTableTableManager(_db, _db.turnosEscala);
  $$AlocacoesTableTableManager get alocacoes =>
      $$AlocacoesTableTableManager(_db, _db.alocacoes);
}
