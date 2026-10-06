#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""A fake AWS CLI for test_provision_ci.sh: only the calls provision-ci.sh makes, over a JSON state file
($FAKE_STATE), each logged to $FAKE_LOG as `<service> <verb> <arguments>`. Errors are printed as the real CLI
prints them (`An error occurred (<Code>) when calling the <Op> operation: …`) with its exit status 254. Every
identifier is a placeholder. Installed by the test as `aws`, first on PATH; it never calls AWS."""

import fcntl
import hashlib
import json
import os
import sys
import uuid

STATE = os.environ["FAKE_STATE"]
WORDS = []
LOG = os.environ["FAKE_LOG"]


class Fail(Exception):
    def __init__(self, code, message="fake error"):
        super().__init__(message)
        self.code = code
        self.message = message


# Options with several values (the CLI's lists; for `lambda invoke`, the payload and then the outfile), and flags.
MULTI = {"attribute-definitions", "key-schema", "payload"}
FLAGS = {"with-decryption"}


def parse(argv):
    """`[service, verb]` and `{option: [values]}`: an option takes one value, every following token that is not an
    option if it is in MULTI, and none if it is a flag. --cli-input-json's file is merged in as `data`."""
    words, options, i = [], {}, 0
    while i < len(argv):
        token = argv[i]
        if token.startswith("--"):
            name, values, i = token[2:], [], i + 1
            if name in MULTI:
                while i < len(argv) and not argv[i].startswith("--"):
                    values.append(argv[i])
                    i += 1
            elif name not in FLAGS and i < len(argv):
                values.append(argv[i])
                i += 1
            options[name] = values
        else:
            words.append(token)
            i += 1
    data = {}
    if "cli-input-json" in options:
        with open(options["cli-input-json"][0][len("file://"):]) as f:
            data = json.load(f)
    return words, options, data


def one(options, name, default=None):
    values = options.get(name)
    return values[0] if values else default


def shorthand(text):
    """`K=V,K2=V2`, or `purpose=x` for logs and S3, as a dict."""
    return dict(part.split("=", 1) for part in text.split(","))


def tag_dict(pairs):
    return {p["Key"]: p["Value"] for p in pairs}


def new_id(state, kind, length=26):
    state["counter"] = state.get("counter", 0) + 1
    seed = hashlib.sha256(f"{kind}{state['counter']}".encode()).hexdigest()
    return seed[:length]


def account(state):
    return state["account"]


def handle(state, service, verb, o, data):
    acct, region = account(state), "us-east-1"
    s = state
    # --- sts, sns, iam -------------------------------------------------------------------------------------
    if (service, verb) == ("sts", "get-caller-identity"):
        return {"Account": acct, "Arn": f"arn:aws:sts::{acct}:assumed-role/FakeAdmin/fake", "UserId": "AROAFAKE:fake"}
    if (service, verb) == ("sns", "get-sms-sandbox-account-status"):
        return {"IsInSandbox": True}
    if service == "iam":
        roles = s.setdefault("roles", {})
        name = one(o, "role-name") or data.get("RoleName")
        if verb == "get-account-summary":
            return {"SummaryMap": {"Roles": len(roles) + 500, "RolesQuota": 1000}}
        if verb == "list-roles":
            return {"Roles": [dict(r["Role"]) for r in roles.values()]}
        if verb == "create-role":
            if name in roles:
                raise Fail("EntityAlreadyExists")
            roles[name] = {"Role": {"RoleName": name, "RoleId": "AROA" + new_id(s, "role", 17).upper(),
                                    "Arn": f"arn:aws:iam::{acct}:role/{name}",
                                    "AssumeRolePolicyDocument": json.loads(data["AssumeRolePolicyDocument"])},
                           "tags": data.get("Tags", []), "inline": {}, "attached": []}
            return {"Role": roles[name]["Role"]}
        if name not in roles:
            raise Fail("NoSuchEntity", "The role cannot be found.")
        role = roles[name]
        if verb == "get-role":
            return {"Role": role["Role"]}
        if verb == "list-role-tags":
            return {"Tags": role["tags"]}
        if verb == "list-attached-role-policies":
            return {"AttachedPolicies": role["attached"]}
        if verb == "list-role-policies":
            return {"PolicyNames": sorted(role["inline"])}
        if verb == "get-role-policy":
            policy = one(o, "policy-name")
            if policy not in role["inline"]:
                raise Fail("NoSuchEntity")
            return {"RoleName": name, "PolicyName": policy, "PolicyDocument": role["inline"][policy]}
        if verb == "put-role-policy":
            role["inline"][data["PolicyName"]] = json.loads(data["PolicyDocument"])
            return {}
        if verb == "update-assume-role-policy":
            with open(one(o, "policy-document")[len("file://"):]) as f:
                role["Role"]["AssumeRolePolicyDocument"] = json.load(f)
            return {}
        if verb == "delete-role-policy":
            del role["inline"][one(o, "policy-name")]
            return {}
        if verb == "delete-role":
            del roles[name]
            return {}
    # --- logs ----------------------------------------------------------------------------------------------
    if service == "logs":
        groups = s.setdefault("log_groups", {})
        if verb == "describe-log-groups":
            prefix = one(o, "log-group-name-prefix", "")
            return {"logGroups": [dict({"logGroupName": n}, **({"retentionInDays": g["retention"]} if g.get("retention") else {}))
                                  for n, g in sorted(groups.items()) if n.startswith(prefix)]}
        if verb == "create-log-group":
            name = one(o, "log-group-name")
            if name in groups:
                raise Fail("ResourceAlreadyExistsException")
            groups[name] = {"tags": shorthand(one(o, "tags")), "retention": None}
            return {}
        if verb == "put-retention-policy":
            groups[one(o, "log-group-name")]["retention"] = int(one(o, "retention-in-days"))
            return {}
        if verb == "list-tags-for-resource":
            name = one(o, "resource-arn").split(":log-group:", 1)[1]
            if name not in groups:
                raise Fail("ResourceNotFoundException")
            return {"tags": groups[name]["tags"]}
        if verb == "delete-log-group":
            del groups[one(o, "log-group-name")]
            return {}
    # --- kms -----------------------------------------------------------------------------------------------
    if service == "kms":
        kms = s.setdefault("kms", {"keys": {}, "aliases": {}})
        if verb == "list-aliases":
            return {"Aliases": [{"AliasName": a, "AliasArn": f"arn:aws:kms:{region}:{acct}:{a}", "TargetKeyId": k}
                                for a, k in sorted(kms["aliases"].items())]}
        if verb == "create-key":
            key_id = str(uuid.UUID(hashlib.md5(new_id(s, "kms").encode()).hexdigest()))
            with open(one(o, "policy")[len("file://"):]) as f:
                policy = json.load(f)
            kms["keys"][key_id] = {"policy": policy, "tags": [shorthand(one(o, "tags"))], "state": "Enabled"}
            return {"KeyMetadata": {"KeyId": key_id, "Arn": f"arn:aws:kms:{region}:{acct}:key/{key_id}"}}
        if verb == "create-alias":
            kms["aliases"][one(o, "alias-name")] = one(o, "target-key-id")
            return {}
        if verb == "delete-alias":
            del kms["aliases"][one(o, "alias-name")]
            return {}
        key_id = one(o, "key-id")
        if key_id not in kms["keys"]:
            raise Fail("NotFoundException")
        key = kms["keys"][key_id]
        if verb == "describe-key":
            return {"KeyMetadata": {"KeyId": key_id, "Arn": f"arn:aws:kms:{region}:{acct}:key/{key_id}",
                                    "KeyState": key["state"]}}
        if verb == "get-key-policy":
            return {"Policy": json.dumps(key["policy"])}
        if verb == "put-key-policy":
            with open(one(o, "policy")[len("file://"):]) as f:
                key["policy"] = json.load(f)
            return {}
        if verb == "list-resource-tags":
            return {"Tags": key["tags"]}
        if verb == "schedule-key-deletion":
            key["state"] = "PendingDeletion"
            return {}
    # --- dynamodb ------------------------------------------------------------------------------------------
    if service == "dynamodb":
        tables = s.setdefault("tables", {})
        name = one(o, "table-name") or (one(o, "resource-arn") or "/").rsplit("/", 1)[1]
        if verb == "list-tables":
            return {"TableNames": sorted(tables)}
        if verb == "create-table":
            tables[name] = {"tags": [shorthand(one(o, "tags"))], "ttl": False}
            return {"TableDescription": {"TableName": name}}
        if name not in tables:
            raise Fail("ResourceNotFoundException")
        if verb == "describe-table":
            return {"Table": {"TableName": name, "TableStatus": "ACTIVE"}}
        if verb == "wait":
            return None
        if verb == "describe-time-to-live":
            return {"TimeToLiveDescription": {"TimeToLiveStatus": "ENABLED" if tables[name]["ttl"] else "DISABLED"}}
        if verb == "update-time-to-live":
            tables[name]["ttl"] = True
            return {}
        if verb == "list-tags-of-resource":
            return {"Tags": tables[name]["tags"]}
        if verb == "delete-table":
            del tables[name]
            return {}
    # --- appsync -------------------------------------------------------------------------------------------
    if service == "appsync":
        apis = s.setdefault("apis", {})
        if verb == "list-graphql-apis":
            return {"graphqlApis": [a["api"] for a in apis.values()]}
        if verb == "create-graphql-api":
            api_id = new_id(s, "api")
            apis[api_id] = {"api": {"apiId": api_id, "name": data["name"], "arn": f"arn:aws:appsync:{region}:{acct}:apis/{api_id}",
                                    "uris": {"GRAPHQL": f"https://{api_id}.appsync-api.{region}.amazonaws.com/graphql"},
                                    "authenticationType": data["authenticationType"]},
                            "tags": data.get("tags", {}), "schema": "NOT_APPLICABLE", "sources": {}, "resolvers": {},
                            "keys": []}
            return {"graphqlApi": apis[api_id]["api"]}
        if verb == "list-tags-for-resource":
            api_id = one(o, "resource-arn").rsplit("/", 1)[1]
            return {"tags": apis[api_id]["tags"]}
        api_id = one(o, "api-id") or data.get("apiId")
        if api_id not in apis:
            raise Fail("NotFoundException")
        api = apis[api_id]
        if verb == "get-schema-creation-status":
            return {"status": api["schema"]}
        if verb == "start-schema-creation":
            api["schema"] = "SUCCESS"
            return {"status": "PROCESSING"}
        if verb == "get-data-source":
            if one(o, "name") not in api["sources"]:
                raise Fail("NotFoundException")
            return {"dataSource": api["sources"][one(o, "name")]}
        if verb == "create-data-source":
            api["sources"][data["name"]] = data
            return {"dataSource": data}
        if verb == "get-resolver":
            key = f"{one(o, 'type-name')}.{one(o, 'field-name')}"
            if key not in api["resolvers"]:
                raise Fail("NotFoundException")
            return {"resolver": api["resolvers"][key]}
        if verb == "create-resolver":
            api["resolvers"][f"{data['typeName']}.{data['fieldName']}"] = data
            return {"resolver": data}
        if verb == "list-api-keys":
            return {"apiKeys": api["keys"]}
        if verb == "create-api-key":
            key = {"id": "da2-" + new_id(s, "apikey"), "description": one(o, "description"), "expires": int(one(o, "expires"))}
            api["keys"].append(key)
            return {"apiKey": key}
        if verb == "delete-graphql-api":
            del apis[api_id]
            return {}
    # --- ssm -----------------------------------------------------------------------------------------------
    if service == "ssm":
        params = s.setdefault("ssm", {})
        name = one(o, "name") or one(o, "resource-id") or data.get("Name")
        if verb == "put-parameter":
            if name in params:
                raise Fail("ParameterAlreadyExists")
            params[name] = {"value": data["Value"], "tags": data.get("Tags", [])}
            return {"Version": 1}
        if name not in params:
            raise Fail("ParameterNotFound" if verb != "list-tags-for-resource" else "InvalidResourceId")
        if verb == "get-parameter":
            value = params[name]["value"] if "with-decryption" in o else "<encrypted>"
            return {"Parameter": {"Name": name, "Type": "SecureString", "Value": value}}
        if verb == "list-tags-for-resource":
            return {"TagList": params[name]["tags"]}
        if verb == "delete-parameter":
            del params[name]
            return {}
    # --- lambda --------------------------------------------------------------------------------------------
    if service == "lambda":
        functions = s.setdefault("lambdas", {})
        if verb == "list-functions":
            return {"Functions": [f["config"] for f in functions.values()]}
        if verb == "create-function":
            name = data["FunctionName"]
            if name in functions:
                raise Fail("ResourceConflictException")
            if not data["Role"].split("/")[-1] in s.get("roles", {}):
                raise Fail("InvalidParameterValueException", "The role defined for the function cannot be assumed by Lambda.")
            config = {k: v for k, v in data.items() if k != "Tags"}
            config.update({"FunctionArn": f"arn:aws:lambda:{region}:{acct}:function:{name}", "State": "Active",
                           "CodeSha256": "fake", "RevisionId": new_id(s, "rev", 8)})
            functions[name] = {"config": config, "tags": data.get("Tags", {}), "policy": [], "zip": one(o, "zip-file")}
            return config
        name = one(o, "function-name") or (one(o, "resource") or "").rsplit(":", 1)[-1]
        name = name.rsplit(":function:", 1)[-1]
        if name not in functions:
            raise Fail("ResourceNotFoundException", "Function not found")
        function = functions[name]
        if verb == "get-function-configuration":
            return function["config"]
        if verb == "wait":
            return None
        if verb == "list-tags":
            return {"Tags": function["tags"]}
        if verb == "get-policy":
            if not function["policy"]:
                raise Fail("ResourceNotFoundException", "No policy")
            return {"Policy": json.dumps({"Statement": function["policy"]})}
        if verb == "add-permission":
            function["policy"].append({"Sid": one(o, "statement-id"), "Principal": {"Service": one(o, "principal")},
                                       "Condition": {"ArnLike": {"AWS:SourceArn": one(o, "source-arn")}}})
            return {"Statement": "{}"}
        if verb == "invoke":
            outfile = o["payload"][-1]
            users = function["config"]["Environment"]["Variables"]["USERNAMES"].split(",")
            with open(outfile, "w") as f:
                json.dump({u: "created" for u in users}, f)
            return {"StatusCode": 200}
        if verb == "delete-function":
            del functions[name]
            return {}
    # --- events --------------------------------------------------------------------------------------------
    if service == "events":
        rules = s.setdefault("rules", {})
        name = one(o, "name") or one(o, "rule") or (one(o, "resource-arn") or "/").rsplit("/", 1)[1]
        if verb == "list-rules":
            return {"Rules": [r["rule"] for r in rules.values()]}
        if verb == "put-rule":
            rules[name] = {"rule": {"Name": name, "Arn": f"arn:aws:events:{region}:{acct}:rule/{name}",
                                    "ScheduleExpression": one(o, "schedule-expression"), "State": "ENABLED"},
                           "tags": [shorthand(one(o, "tags"))], "targets": []}
            return {"RuleArn": rules[name]["rule"]["Arn"]}
        if name not in rules:
            raise Fail("ResourceNotFoundException")
        if verb == "describe-rule":
            return rules[name]["rule"]
        if verb == "list-targets-by-rule":
            return {"Targets": rules[name]["targets"]}
        if verb == "put-targets":
            target = shorthand(one(o, "targets"))
            rules[name]["targets"].append(target)
            return {"FailedEntryCount": 0}
        if verb == "list-tags-for-resource":
            return {"Tags": rules[name]["tags"]}
        if verb == "remove-targets":
            rules[name]["targets"] = []
            return {"FailedEntryCount": 0}
        if verb == "delete-rule":
            del rules[name]
            return {}
    # --- cognito-identity ----------------------------------------------------------------------------------
    if service == "cognito-identity":
        pools = s.setdefault("identity_pools", {})
        if verb == "list-identity-pools":
            return {"IdentityPools": [{"IdentityPoolId": i, "IdentityPoolName": p["IdentityPoolName"]} for i, p in pools.items()]}
        if verb == "create-identity-pool":
            pool_id = f"{region}:{uuid.UUID(hashlib.md5(new_id(s, 'ip').encode()).hexdigest())}"
            pools[pool_id] = dict(data, IdentityPoolId=pool_id, roles={})
            return {k: v for k, v in pools[pool_id].items() if k != "roles"}
        pool_id = one(o, "identity-pool-id") or data.get("IdentityPoolId") or one(o, "resource-arn", "").rsplit("/", 1)[-1]
        if pool_id not in pools:
            raise Fail("ResourceNotFoundException")
        pool = pools[pool_id]
        if verb == "describe-identity-pool":
            return {k: v for k, v in pool.items() if k not in ("roles", "IdentityPoolTags")}
        if verb == "get-identity-pool-roles":
            return {"IdentityPoolId": pool_id, "Roles": pool["roles"]}
        if verb == "set-identity-pool-roles":
            pool["roles"] = data["Roles"]
            return {}
        if verb == "list-tags-for-resource":
            return {"Tags": pool.get("IdentityPoolTags", {})}
        if verb == "delete-identity-pool":
            del pools[pool_id]
            return {}
    # --- cognito-idp ---------------------------------------------------------------------------------------
    if service == "cognito-idp":
        pools = s.setdefault("pools", {})
        if verb == "list-user-pools":
            return {"UserPools": [{k: p["UserPool"][k] for k in ("Id", "Name", "LambdaConfig", "LastModifiedDate",
                                                                 "CreationDate") if k in p["UserPool"]}
                                  for p in pools.values()]}
        if verb == "create-user-pool":
            pool_id = f"{region}_Fake{new_id(s, 'pool', 6)}"
            pool = {k: v for k, v in data.items() if k != "PoolName"}
            pool.update({"Id": pool_id, "Name": data["PoolName"], "EstimatedNumberOfUsers": 0,
                         "LastModifiedDate": "2026-10-05T00:00:00Z", "CreationDate": "2026-10-05T00:00:00Z",
                         "Arn": f"arn:aws:cognito-idp:{region}:{acct}:userpool/{pool_id}"})
            pools[pool_id] = {"UserPool": pool, "clients": {}, "mfa": {"MfaConfiguration": "OFF"}}
            return {"UserPool": pool}
        pool_id = one(o, "user-pool-id") or data.get("UserPoolId")
        if pool_id not in pools:
            raise Fail("ResourceNotFoundException", "User pool does not exist.")
        pool = pools[pool_id]
        if verb == "describe-user-pool":
            return {"UserPool": pool["UserPool"]}
        if verb == "get-user-pool-mfa-config":
            return pool["mfa"]
        if verb == "set-user-pool-mfa-config":
            pool["mfa"] = {k: v for k, v in data.items() if k != "UserPoolId"}
            return pool["mfa"]
        if verb == "list-user-pool-clients":
            return {"UserPoolClients": [{"ClientId": c, "ClientName": v["ClientName"], "UserPoolId": pool_id}
                                        for c, v in pool["clients"].items()]}
        if verb == "create-user-pool-client":
            client_id = new_id(s, "client")
            pool["clients"][client_id] = dict({k: v for k, v in data.items() if k != "GenerateSecret"}, ClientId=client_id)
            return {"UserPoolClient": pool["clients"][client_id]}
        if verb == "describe-user-pool-client":
            client_id = one(o, "client-id")
            if client_id not in pool["clients"]:
                raise Fail("ResourceNotFoundException")
            return {"UserPoolClient": pool["clients"][client_id]}
        if verb == "delete-user-pool":
            del pools[pool_id]
            return {}
    # --- s3api ---------------------------------------------------------------------------------------------
    if service == "s3api":
        objects = s.setdefault("s3", {})
        if one(o, "bucket") != s["bucket"]:
            raise Fail("NoSuchBucket")
        key = one(o, "key")
        if verb == "list-objects-v2":
            prefix = one(o, "prefix", "")
            return {"Contents": [{"Key": k, "ETag": v["etag"], "Size": v["size"], "LastModified": v["modified"],
                                  "StorageClass": "STANDARD"} for k, v in sorted(objects.items()) if k.startswith(prefix)]}
        if verb == "put-object":
            if key in objects and one(o, "if-none-match") == "*":
                raise Fail("PreconditionFailed", "At least one of the pre-conditions you specified did not hold")
            with open(one(o, "body"), "rb") as f:
                body = f.read()
            objects[key] = {"etag": '"%s"' % hashlib.md5(body).hexdigest(), "size": len(body),
                            "modified": "2026-10-05T00:00:00Z", "tags": shorthand(one(o, "tagging", "none=none")),
                            "body": body.decode()}
            return {"ETag": objects[key]["etag"]}
        if key not in objects:
            raise Fail("404", "Not Found")
        if verb == "get-object":
            with open(o["outfile"][0] if "outfile" in o else WORDS[-1], "w") as f:
                f.write(objects[key].get("body", ""))
            return {"ETag": objects[key]["etag"]}
        if verb == "head-object":
            return {"ETag": objects[key]["etag"], "ContentLength": objects[key]["size"]}
        if verb == "get-object-tagging":
            return {"TagSet": [{"Key": k, "Value": v} for k, v in objects[key]["tags"].items()]}
        if verb == "delete-object":
            del objects[key]
            return {}
    raise Fail("FakeUnsupported", f"the fake has no {service} {verb}")


def main():
    argv = sys.argv[1:]
    with open(LOG, "a") as log:
        log.write(" ".join(argv) + "\n")
    if argv[:1] == ["--version"]:
        print("aws-cli/2.31.32 Python/3.13 Darwin/25 source/arm64")
        return 0
    if argv[:2] == ["configure", "get"]:
        return 1
    global WORDS
    words, options, data = parse(argv)
    WORDS = words
    service, verb = words[0], words[1]
    with open(STATE + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        with open(STATE) as f:
            state = json.load(f)
        try:
            # FAKE_FAIL_ONCE="<service> <verb> <code>" fails the first such call, as IAM propagation or an outage would.
            fail_once = os.environ.get("FAKE_FAIL_ONCE", "").split()
            if fail_once[:2] == [service, verb] and not state.get("failed_once"):
                state["failed_once"] = True
                with open(STATE, "w") as f:
                    json.dump(state, f, indent=1, sort_keys=True)
                raise Fail(fail_once[2], "injected by FAKE_FAIL_ONCE")
            result = handle(state, service, verb, options, data)
        except Fail as error:
            operation = "".join(part.capitalize() for part in verb.split("-"))
            print(f"\nAn error occurred ({error.code}) when calling the {operation} operation: {error.message}",
                  file=sys.stderr)
            return 254
        # Reads leave the file as it was (the lookups above add empty collections as they go).
        if not verb.startswith(("get-", "list-", "describe-", "head-")) and verb != "wait":
            with open(STATE, "w") as f:
                json.dump(state, f, indent=1, sort_keys=True)
    if result is not None:
        print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
